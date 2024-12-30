from hashlib import sha256

# SIZE = 256
# serial = [0x0] * SIZE
# serial[0] = 2

from mapped_data import data
from hashes import hashes, single_hashes, hashes_bytes

known = {
	0x11: 0xff,

	0x60: 0x0b,
	0x61: 0x0f,
	0x62: 0x09,
	0x63: 0x0c,
	0x64: 0x0a,
	0x65: 0x0d,
	0x66: 0x00,
	0x67: 0x07,
	0x68: 0x02,
	0x69: 0x03,
	0x6a: 0x05,
	0x6b: 0x0e,
	0x6c: 0x04,
	0x6d: 0x01,
	0x6e: 0x08,
	0x6f: 0x06,

	0x70: 0x7b,

	0x75: 0x7d,

	0x79: 0x73,

	# 0x7f: 

	0x85: 0x2d,

	0x8a: 0x25,

	0x9d: 0x31,

	0xa6: 0x50,

	0xac: 0x54,

	0xbe: 0xe8,

	0xc7: 0x47,
	0xc8: 0x42,
	0xc9: 0x43,
	0xca: 0x45,
	
	0xcc: 0x44,
	
	0xce: 0x48,
	0xcf: 0x46,

	0xd6: 0x10,

	0xf2: 0x69,


	# 0xAB: 0x2D, # PUSH.W
	# 0xB2: 0xE9, # PUSH.W
}

high = {}
low = {}

for key, value in known.items():
	ks = hex(key)[2:].rjust(2, '0')
	vs = hex(value)[2:].rjust(2, '0')

	high[ks[0]] = vs[0]
	low[ks[1]] = vs[1]

# print(high)
# print(low)

k2 = {}


for h, hv in high.items():
	for l, lv in low.items():
		k2[int(h + l, 16)] = int(hv + lv, 16)

# known = k2


k3 = {}

for l1, v1 in low.items():
	for l2, v2 in low.items():
		k3[int(l1 + l2, 16)] = int(v1 + v2, 16)

print('{', end='')
for k, v in k3.items():
	print(f'{hex(k)}: 0x{hex(v)[2:].rjust(2, "0")},', end=' ')
print('}')

# for k, v in k3.items():
# 	print(hex(k), hex(v))

# known = k3

# for k, v in known.items():
# 	print(hex(k), hex(v))



# area_size = len(data) # 0x1000 | 4096

# i = 0
# while i < area_size:
# 	while True:
# 		oddness = i & 1
# 		j = i
# 		if i > 0x2DB: # 731
# 			oddness = 1
# 		i += 1
# 		if oddness:
# 			break
# 		data[j] = serial[data[j]]
# 	data[j] = serial[data[j] & 0xF] | (16 * serial[data[j] >> 4])

# print(data)



# for i in range(256):
# 	block = bytes([i] * 16)
# 	h = sha256(block).digest()
# 	if h in hashes_bytes:
# 		for j, b in enumerate(hashes_bytes):
# 			if b == h:
# 				print(j, i)
		#print(i, h)


# d 1 2 3
# f a b c

k4 = {
	0xAB: 0x2D,
	# 0x81: 0xf0,
}

code = b''

for i in range(110):
	idx = i * 16
	even = data[idx:idx+16:2]
	d = [x for x in even if x not in k4]
	l = len(set(d))
	# if l:
	# 	print(i, l)

	# if i < 45:
	# 	continue

	# if l == 0:
	# 	print(i)

	if i > 45:
		continue

	# print(i, l)

	# if l < 6:
	# 	print('=' * 10)
	# continue

	# for b in data[idx:idx+16]:
	# 	curr = k3[b]
	# 	code += bytes([curr])

	for j, b in enumerate(data[idx:idx+16]):
		if j & 1:
			print(hex(k3[b])[2:].rjust(2, '0'), end='')
		else:
			print('_', end='')
	#print()


	continue

	if 0 < l < 5:

		# tmp = data[idx:idx+16]
		# if tmp[0] == tmp[1] == tmp[2] == tmp[3] and \
		# 	tmp[4] == tmp[5] == tmp[6] == tmp[7] and \
		# 	tmp[8] == tmp[9] == tmp[10] == tmp[11] and \
		# 	tmp[12] == tmp[13] == tmp[14] == tmp[15]:
		
		print()
		print()
		print()

		print(i, l)

		print([hex(x)[2:] for x in data[idx:idx+16]])
		print(hashes_bytes[i].hex())
		print([x for x in hashes_bytes[i]])

		print()
		print()
		print()

		unk = [
			'blockIdx.x',
			'blockIdx.y',
			'blockIdx.z',
			'threadIdx.x',
		]
		mapper = {}

		for j, el in enumerate(data[idx:idx+16]):
			if el in known:
				print(f'key[{j}] = {hex(known[el])};')
			elif (j&1):
				print(f'key[{j}] = {hex(k3[el])};')
			else:
				if el not in mapper:
					mapper[el] = unk.pop()
				print(f'key[{j}] = {mapper[el]};')

print()

# with open('code', 'wb') as f:
# 	f.write(code)

# from pwn import disasm

# a = disasm(code, arch='arm')

# print(a)
# print(code)

# test = bytes([

# ])

# h = sha256(test).hexdigest()
# print(h)
# print(hashes_bytes[i].hex())


# for i in range(97, 106):
# 	print([hex(x)[2:] for x in data[16*i:16*(i+1)]])




# hexadecimal = '0123456789abcdef'
# d = data[16*105:16*106]

# for x8 in hexadecimal:
# 	for x7 in hexadecimal:
# 		tmp = []
# 		for b in d:
# 			if b in known:
# 				tmp.append(known[b])
# 			else:
# 				h = hex(b)[2:].rjust(2, '0')
# 				if '7' in h[0]:
# 					tmp.append(int(x7 + low[h[1]], 16))
# 				elif '8' in h[0]:
# 					tmp.append(int(x8 + low[h[1]], 16))
# 				else:
# 					print('Error')
# 				#print(h, hex(tmp[-1])[2:])
# 		tmp = bytes(tmp)
# 		#print(tmp.hex())
# 		h = sha256(tmp).digest()
# 		if h[:32] == hashes_bytes[105][:32]:
# 			print(x7, x8)
# 			print([hex(n)[2:] for n in tmp])
# 			print([hex(n)[2:] for n in d])
# 			print('Found')
# 			exit()


# hexadecimal = '0123456789abcdef'
# d = data[16*97:16*98]

# for xf in hexadecimal:
# 	tmp = []
# 	for b in d:
# 		if b in known:
# 			tmp.append(known[b])
# 		else:
# 			h = hex(b)[2:].rjust(2, '0')
# 			if 'f' in h[0]:
# 				tmp.append(int(xf + low[h[1]], 16))
# 			else:
# 				print('Error')
# 			#print(h, hex(tmp[-1])[2:])
# 	tmp = bytes(tmp)
# 	#print(tmp.hex())
# 	h = sha256(tmp).digest()
# 	if h[:32] == hashes_bytes[97][:32]:
# 		print(xf)
# 		print([hex(n)[2:] for n in tmp])
# 		print([hex(n)[2:] for n in d])
# 		print('Found')
# 		exit()
	