import struct, zlib, os
from PIL import Image

data = open('tmp/HabboAir_uncompressed.bin','rb').read()
out = 'src/images/'
os.makedirs(out, exist_ok=True)

pos = 0
nbits = data[pos] >> 3
rect_bytes = (5 + nbits * 4 + 7) // 8
pos += rect_bytes
pos += 4

cids = {
    1455: 'HabboWindowManagerCom_illumina_purple_border_frame_png',
    1413: 'HabboWindowManagerCom_illumina_purple_button_default_png',
    1012: 'HabboWindowManagerCom_illumina_purple_button_frame_close_png',
    1246: 'HabboNotificationsCom_discord_box_png',
    1465: 'HabboNotificationsCom_icon_curator_stamp_large_png',
    1837: 'HabboNotificationsCom_icon_curator_stamp_large_png',
    # Added the wired and origin logo mapping based on likely symbols...
    # Wait, what are their CIDs? Let's dump all SymbolClass!
}

# Let's quickly dump all symbols to find discord_wired_logo
found_symbols = {}
p = pos
while p < len(data):
    try:
        tag_code_and_length = struct.unpack('<H', data[p:p+2])[0]
    except: break
    p += 2
    length = tag_code_and_length & 0x3F
    if length == 0x3F:
        length = struct.unpack('<I', data[p:p+4])[0]
        p += 4
    if (tag_code_and_length >> 6) == 76:
        num_sym = struct.unpack('<H', data[p:p+2])[0]
        offset = p + 2
        for _ in range(num_sym):
            cid = struct.unpack('<H', data[offset:offset+2])[0]
            offset += 2
            n_end = data.find(b'\0', offset)
            nm = data[offset:n_end].decode('utf-8','ignore')
            offset = n_end + 1
            if 'discord' in nm or 'origin' in nm:
                print(f"SYMBOL: {cid} -> {nm}")
                cids[cid] = "HabboNotificationsCom_" + nm
    p += length

print("Extracting...")
while pos < len(data):
    try:
        tag_code_and_length = struct.unpack('<H', data[pos:pos+2])[0]
    except Exception: break
    pos += 2
    tag_code = tag_code_and_length >> 6
    length = tag_code_and_length & 0x3F
    if length == 0x3F:
        length = struct.unpack('<I', data[pos:pos+4])[0]
        pos += 4
    end = pos + length

    if tag_code == 21:
        cid = struct.unpack('<H', data[pos:pos+2])[0]
        if cid in cids:
            name = cids[cid]
            img_data = data[pos+2:end]
            # It's a PNG/JPG. Just write bytes:
            open(out + name + '.png', 'wb').write(img_data)
            as_code = f'package {{\nimport mx.core.BitmapAsset;\n[Embed(source="{name}.png")]\npublic class {name} extends BitmapAsset {{}}\n}}'
            open(f'src/binaryData/{name}.as', 'w').write(as_code)

    elif tag_code == 36:
        cid, fmt, w, h = struct.unpack('<HBHH', data[pos:pos+7])
        if cid in cids:
            print(f"Decoding tag 36 CID {cid}")
            zdata = data[pos+7:end]
            pixels = bytearray(zlib.decompress(zdata))
            rgba = bytearray(len(pixels))
            # Just rough decode to test
            for i in range(0, len(pixels), 4):
                a = pixels[i]
                rgba[i+3] = a
                if a > 0:
                    rgba[i] = min(255, pixels[i+1]*255//a)
                    rgba[i+1] = min(255, pixels[i+2]*255//a)
                    rgba[i+2] = min(255, pixels[i+3]*255//a)
            img = Image.frombytes('RGBA', (w,h), bytes(rgba))
            name = cids.get(cid)
            img.save(out + name + '.png')
            as_code = f'package {{\nimport mx.core.BitmapAsset;\n[Embed(source="{name}.png")]\npublic class {name} extends BitmapAsset {{}}\n}}'
            open(f'src/binaryData/{name}.as', 'w').write(as_code)
            
    pos = end
