import re

def parse_lua_string(s, start_marker='local _d="'):
    idx = s.find(start_marker)
    if idx < 0:
        return None
    idx += len(start_marker)
    parts = []
    i = idx
    while i < len(s):
        ch = s[i]
        if ch == '\\':
            # 解析转义
            if i + 1 >= len(s):
                break
            esc = s[i+1]
            if esc == 'n':
                parts.append('\n')
            elif esc == 'r':
                parts.append('\r')
            elif esc == 't':
                parts.append('\t')
            elif esc == '\\':
                parts.append('\\')
            elif esc == '"':
                parts.append('"')
            elif esc == "'":
                parts.append("'")
            elif esc == '0':
                # \000 到 \255 三位八进制
                if i + 4 <= len(s):
                    oct_str = s[i+1:i+4]
                    try:
                        val = int(oct_str, 8)
                        parts.append(chr(val))
                        i += 3
                    except ValueError:
                        parts.append(esc)
                        i += 1
                else:
                    parts.append(esc)
                    i += 1
            elif esc in '01234567':
                # 三位八进制
                if i + 4 <= len(s):
                    oct_str = s[i+1:i+4]
                    try:
                        val = int(oct_str, 8)
                        parts.append(chr(val))
                        i += 3
                    except ValueError:
                        parts.append(esc)
                        i += 1
                else:
                    parts.append(esc)
                    i += 1
            else:
                parts.append(esc)
            i += 2
        elif ch == '"':
            break
        else:
            parts.append(ch)
            i += 1
    return ''.join(parts), i

files = [
    'C:/熊猫人/World of Warcraft/_classic_titan_/Interface/AddOns/ZZHELPER8月21日/UpdateContent.lua',
    'C:/熊猫人/World of Warcraft/_classic_titan_/Interface/AddOns/ZZHELPER8月21日/UI.lua',
    'C:/熊猫人/World of Warcraft/_classic_titan_/Interface/AddOns/ZZHELPER8月21日/Main.lua',
    'C:/熊猫人/World of Warcraft/_classic_titan_/Interface/AddOns/ZZHELPER8月21日/Combat.lua',
]

for path in files:
    try:
        with open(path, 'rb') as f:
            raw = f.read()
        data = raw.decode('latin1', errors='ignore')
        m_k = re.search(r'local _k=\{([^}]+)\}', data)
        parsed = parse_lua_string(data)
        if not m_k or not parsed:
            print(f"跳过 {path}: 未找到 _k/_d")
            continue
        keys = [int(x.strip()) for x in m_k.group(1).split(',')]
        d, end_idx = parsed
        print(f"  {path}: _k长度={len(keys)}, _d长度={len(d)}")
        out = []
        for i, ch in enumerate(d):
            b = ord(ch)
            k = keys[i % len(keys)]
            out.append(chr(b ^ k))
        out_path = path + '.decrypted.lua'
        with open(out_path, 'wb') as f:
            f.write(''.join(out).encode('utf-8', errors='replace'))
        print(f"解密 {path} -> {out_path}, 输出长度 {len(out)}")
    except Exception as e:
        print(f"错误 {path}: {e}")
        import traceback
        traceback.print_exc()
