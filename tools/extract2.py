import struct, zlib, os
from PIL import Image

data = open('tmp/HabboAir_uncompressed.bin','rb').read()
out = 'src/images/'
os.makedirs(out, exist_ok=True)

cids = {
    1455: 'HabboWindowManagerCom_illumina_purple_border_frame_png',
    1413: 'HabboWindowManagerCom_illumina_purple_button_default_png',
    1012: 'HabboWindowManagerCom_illumina_purple_button_frame_close_png',
    1246: 'HabboNotificationsCom_discord_box_png',
    1465: 'HabboNotificationsCom_icon_curator_stamp_large_png',
    1837: 'HabboNotificationsCom_icon_curator_stamp_large_png'
}

idx = 0
found = 0
print(f"Scanning {len(data)} bytes for Lossless2 tags...")

while True:
    idx = data.find(b'\x3f\x09', idx)
    if idx < 0: break
    
    # Try parsing
    try:
        length = struct.unpack('<I', data[idx+2:idx+6])[0]
        if length > 10000000: # sanity check
            idx += 1
            continue
            
        cid, fmt, w, h = struct.unpack('<HBHH', data[idx+6:idx+13])
        if cid in cids:
            print(f"Found {cids[cid]} at offset {idx}")
            zdata = data[idx+13:idx+6+length]
            pixels = bytearray(zlib.decompress(zdata))
            rgba = bytearray(len(pixels))
            for i in range(0, len(pixels), 4):
                a = pixels[i]
                rgba[i+3] = a
                if a > 0:
                    rgba[i] = min(255, pixels[i+1]*255//a)
                    rgba[i+1] = min(255, pixels[i+2]*255//a)
                    rgba[i+2] = min(255, pixels[i+3]*255//a)
            img = Image.frombytes('RGBA', (w,h), bytes(rgba))
            img.save(out + cids[cid] + '.png')
            
            # create AS wrapper
            as_code = f'package {{\nimport mx.core.BitmapAsset;\n[Embed(source="{cids[cid]}.png")]\npublic class {cids[cid]} extends BitmapAsset {{}}\n}}'
            open(f'src/binaryData/{cids[cid]}.as', 'w').write(as_code)
            found += 1
    except Exception as e:
        pass
    idx += 1

print(f"Done, extracted {found} target images.")
