import ida_hexrays
import ida_lines
import ida_funcs
import ida_kernwin
import idautils
import idc

start = 0x500000
size = 0x1000


with open('decoded2', 'rb') as f:
	data = f.read()

for i, b in enumerate(data):
	patch_byte(start + i, b)

