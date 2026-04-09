# Encryption & Handshake

The Habbo protocol uses a two-step crypto setup: **RSA** authenticates a Diffie–Hellman key exchange, then the derived shared secret seeds a pair of **RC4 (ArcFour)** stream ciphers. Once the handshake completes, every [wire frame](Wire-Format) — length prefix and payload — is transparently enciphered.

## Crypto Components

| Primitive  | Purpose                                             | Class                                                                         |
|------------|-----------------------------------------------------|-------------------------------------------------------------------------------|
| RSA        | Authenticates DH prime, generator, and public keys  | `src/com/sulake/core/communication/encryption/rsa/RSAKey.as`                  |
| DH         | Forward-secure shared-secret exchange               | `src/com/sulake/habbo/communication/encryption/DiffieHellman.as`              |
| RC4        | Symmetric stream cipher for every frame post-handshake | `src/com/sulake/habbo/communication/encryption/ArcFour.as`                 |
| BigInteger | Large integer math for RSA/DH                       | `com.hurlant.math.BigInteger` (vendored)                                      |
| Hex tools  | Byte/hex conversion throughout handshake            | `src/com/sulake/core/communication/encryption/CryptoTools.as`                 |

All three cipher types implement a small interface so the connection layer does not need to know which is in use:

**`IEncryption`** — `src/com/sulake/core/communication/encryption/IEncryption.as`
```actionscript
function init(key:ByteArray):void;
function encipher(data:ByteArray):ByteArray;
function decipher(data:ByteArray):ByteArray;
function mark():void;   // snapshot state for rollback
function reset():void;  // restore last mark()
```

The `mark()`/`reset()` pair is essential for stream ciphers: when the TCP buffer holds a partial frame, the decoder decrypts the 4-byte length, finds out it's short on payload, and must rewind the cipher state. See `EvaWireFormat.decode()` lines 84 and 109–112.

## ArcFour (RC4)

**`ArcFour`** is a textbook RC4 implementation with state `(i, j, sbox[256])`. Both `encipher` and `decipher` apply the same XOR-with-keystream operation; the asymmetry in the code is only that `encipher` uses `% 0x100` while `decipher` uses `& 0xFF` — equivalent.

- **Init** (`ArcFour.as:22-44`): standard KSA — fill S-box with `0..255`, then shuffle using the key material.
- **Mark/Reset** (`ArcFour.as:86-98`): stashes `i`, `j`, and a copy of the S-box so the decoder can roll back after a short read.

Both directions use the **same RC4 key** — the DH shared secret — but each direction gets its own `ArcFour` instance so their keystreams remain independent. This is set up in `HabboCommunicationDemo.onCompleteDiffieHandshake` lines 379–386:

```actionscript
var outgoingEncryption:IEncryption = this._communication.initializeEncryption();
outgoingEncryption.init(sharedKeyBytes);
if (event.serverClientEncryption)
{
    incomingEncryption = this._communication.initializeEncryption();
    incomingEncryption.init(sharedKeyBytes);
}
connection.setEncryption(outgoingEncryption, incomingEncryption);
```

**Server → client encryption is optional.** The `CompleteDiffieHandshake` message carries a trailing `Boolean` — if `false`, only client → server traffic is enciphered and incoming frames stay in the clear. This is controlled by `CompleteDiffieHandshakeParser.as:20-23`.

## Diffie-Hellman

**`DiffieHellman`** (`DiffieHellman.as`) is a straightforward implementation using `BigInteger.modPow`:

```actionscript
this._publicKey = this._generator.modPow(this._privateKey, this._prime);
// ...
this._sharedKey = this._serverPublicKey.modPow(this._privateKey, this._prime);
```

The prime and generator are **not hard-coded** — they're delivered by the server in `InitDiffieHandshakeEvent` (packet ID 1347) wrapped in RSA signatures the client verifies. This means the hotel operator rotates DH parameters server-side without reshipping the SWF.

Two validity guards exist:
- `isValidServerPublicKey()` — rejects server public key `< 2`
- `isValidSharedKey()` — rejects shared secret `< 2`

Additionally, after RSA-verifying the prime and generator, the client rejects them if `prime <= 2`, `generator >= prime`, or `prime == generator` (`HabboCommunicationDemo.as:315-324`).

## Handshake Sequence

```
Client                                        Server
  │                                              │
  │  ── ClientHello (unencrypted) ──────────────▶│  packet 4000
  │      empty composer                          │  (see ClientHelloMessageComposer)
  │                                              │
  │  ◀── InitDiffieHandshake ─────────────────── │  packet 1347
  │      {encryptedPrime, encryptedGenerator}    │  RSA-signed DH params
  │                                              │
  │  RSA.verify(prime), RSA.verify(generator)    │
  │  Validate 2 < prime, gen < prime, gen != prime│
  │  DH.init(privateKey)                         │
  │  pubKey = g^priv mod prime                   │
  │  encPub = RSA.encrypt(pubKey)                │
  │                                              │
  │  ── CompleteDiffieHandshake ────────────────▶│  packet 773
  │      { encryptedClientPublicKey }  (plain)   │
  │                                              │
  │  ◀── CompleteDiffieHandshake ───────────────│  packet 3885
  │      { encryptedServerPublicKey,             │
  │        serverClientEncryption:Boolean }      │
  │                                              │
  │  RSA.verify(serverPublicKey)                 │
  │  sharedKey = serverPub^priv mod prime        │
  │  RC4(out).init(sharedKey)                    │
  │  if (serverClientEncryption)                 │
  │     RC4(in).init(sharedKey)                  │
  │  connection.setEncryption(out, in)           │
  │                                              │
  │  ═══ ALL FRAMES NOW ENCRYPTED ═══            │
  │                                              │
  │  ── VersionCheck ───────────────────────────▶│  packet (see HabboMessages)
  │  ── SSOTicket ──────────────────────────────▶│
  │  ── UniqueID ──────────────────────────────▶│
  │  ── InfoRetrieve ──────────────────────────▶│
```

**Source:** `src/com/sulake/habbo/communication/demo/HabboCommunicationDemo.as:284-389`

### RSA public key

The hardcoded RSA public key (used to verify the server's DH parameters) is at `HabboCommunicationDemo.as:309`. Modulus is a 256-hex-digit value and the public exponent is `"3"`. To talk to a non-Sulake server you must replace this key to match the new RSA keypair.

### Pre-encryption path for handshake composers

Outgoing handshake composers implement the extra marker interface `IPreEncryptionMessage`:

```actionscript
public class InitDiffieHandshakeMessageComposer implements IMessageComposer, IPreEncryptionMessage
```

The connection layer uses this marker to decide whether to call `connection.sendUnencrypted()` or `connection.send()`. The handshake itself is always clear-text; only after `setEncryption()` does the stream switch to RC4.

## Connection-Layer Integration

`EvaWireFormat.decode()` queries the connection for an `IEncryption` instance every frame:

```actionscript
encryption = socket.getServerToClientEncryption();
if (encryption != null)
{
    encryption.mark();
    // ...read and decrypt length bytes...
}
```

If `encryption == null` (handshake phase, or server→client encryption disabled), length bytes are read directly with `buffer.readInt()`. The same dual-path exists for the payload further down the method.

On encode, the client applies the outgoing RC4 inside the connection's send path (not `EvaWireFormat.encode()` itself) — the wire format produces a clear-text frame which the connection then enciphers in one call before writing to the socket.

## Threat Model Notes

- **Homemade protocol.** RC4 is considered broken for modern use (biased keystream, related-key attacks). The client is a historical artifact; don't lift this design into new software.
- **Single-key bidirectional RC4.** Using the same key on both directions is a classic RC4 footgun — two keystreams derived from the same key on different plaintexts allow ciphertext-only biases to combine. Habbo's server-side deployment historically mitigated this by disabling server → client encryption (`event.serverClientEncryption == false`), which is why that switch exists.
- **No integrity check.** Neither the wire format nor the cipher provides authentication. A man in the middle who can predict keystream bits (RC4 bias) can flip individual ciphertext bits without detection.
- **RSA-e=3** with no padding discipline is also weak; it's only used to authenticate the DH parameters, not for confidentiality of anything else.

For a **private/retro server**, this is fine — you control both ends and the primary goal is keeping casual traffic sniffers out. For anything production-security-sensitive, use TLS.

## Key Files

| File                                                                            | Purpose                                     |
|---------------------------------------------------------------------------------|---------------------------------------------|
| `src/com/sulake/habbo/communication/encryption/ArcFour.as`                      | RC4 implementation                          |
| `src/com/sulake/habbo/communication/encryption/DiffieHellman.as`                | DH key exchange                             |
| `src/com/sulake/core/communication/encryption/IEncryption.as`                   | Encryption interface used by connection    |
| `src/com/sulake/core/communication/encryption/CryptoTools.as`                   | Hex/bytes helpers                           |
| `src/com/sulake/core/communication/encryption/rsa/RSAKey.as`                    | RSA implementation                          |
| `src/com/sulake/core/communication/handshake/IKeyExchange.as`                   | DH interface                                |
| `src/com/sulake/habbo/communication/demo/HabboCommunicationDemo.as`             | Handshake orchestration (`onInitDiffie…`)   |
| `src/com/hurlant/math/BigInteger.as`                                            | Vendored BigInteger math                    |

## See Also

- [Wire Format](Wire-Format) — how frames are framed before/after encryption
- [Message Pattern](Message-Pattern) — how `IPreEncryptionMessage` is signalled
- [Packet Reference](Packet-Reference) — handshake packet IDs (1347, 3885, 773, 4000)
