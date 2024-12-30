#include <iostream>
#include <cuda.h>
#include <curand_kernel.h>
#include <map>


// __host__ __device__ unsigned char KNOWN_HASH[64] = {59, 191, 88, 123, 36, 146, 58, 115, 132, 105, 177, 202, 38, 104, 59, 214, 21, 242, 86, 124, 137, 177, 181, 43, 144, 226, 92, 197, 48, 229, 149, 153};
// __host__ __device__ unsigned char KNOWN_HASH[64] = {112, 149, 232, 60, 94, 84, 150, 4, 140, 167, 143, 41, 10, 191, 50, 14, 132, 137, 152, 231, 198, 168, 12, 172, 154, 231, 213, 213, 2, 45, 81, 47};
// __host__ __device__ unsigned char KNOWN_HASH[64] = {127, 184, 0, 44, 43, 64, 93, 197, 133, 89, 171, 248, 202, 111, 49, 215, 102, 70, 221, 158, 162, 53, 207, 64, 161, 43, 55, 171, 235, 49, 161, 65};
// __host__ __device__ unsigned char KNOWN_HASH[64] = {194, 247, 123, 195, 214, 51, 54, 218, 231, 2, 134, 132, 163, 113, 233, 60, 26, 178, 184, 2, 10, 234, 147, 113, 254, 78, 40, 27, 137, 189, 152, 236};
// __host__ __device__ unsigned char KNOWN_HASH[64] = {170, 246, 158, 40, 181, 22, 27, 160, 23, 21, 23, 222, 196, 187, 131, 44, 78, 46, 214, 157, 9, 132, 133, 91, 41, 163, 190, 20, 48, 217, 42, 28};
// __host__ __device__ unsigned char KNOWN_HASH[64] = {115, 129, 228, 97, 46, 37, 50, 178, 118, 254, 69, 105, 174, 109, 55, 24, 81, 162, 174, 65, 10, 226, 179, 159, 0, 29, 62, 106, 183, 216, 4, 25};
// __host__ __device__ unsigned char KNOWN_HASH[64] = {8, 46, 173, 223, 28, 3, 191, 159, 188, 164, 74, 16, 13, 154, 205, 220, 100, 131, 57, 147, 199, 36, 207, 46, 107, 139, 251, 29, 254, 200, 166, 187};
// __host__ __device__ unsigned char KNOWN_HASH[64] = {110, 46, 221, 45, 107, 246, 56, 150, 162, 221, 119, 179, 55, 89, 20, 199, 141, 242, 24, 195, 70, 58, 113, 115, 236, 153, 18, 149, 210, 56, 123, 223};
// __host__ __device__ unsigned char KNOWN_HASH[64] = {214, 248, 149, 169, 198, 33, 206, 60, 210, 7, 191, 8, 253, 165, 179, 57, 32, 194, 12, 143, 119, 39, 63, 37, 131, 220, 117, 218, 0, 220, 111, 32};
__device__ unsigned char KNOWN_HASH[64] = {
160, 5, 39, 204, 12, 127, 104, 209, 61, 132, 91, 14, 121, 241, 242, 183, 120, 89, 74, 124, 63, 128, 178, 205, 192, 103, 107, 40, 209, 31, 66, 93

};



// https://docs.nvidia.com/cuda/cuda-runtime-api/group__CUDART__TYPES.html
#define CHECK(val) check_cuda( (val), #val, __FILE__, __LINE__ )
void check_cuda(cudaError_t res, const char *func, const char *file, const int line)
{
	if (!res)
		return ;
	std::cerr << "CUDA error = " << static_cast<unsigned int>(res);
	std::cerr << " at " << file << ":" << line << " '" << func << "' \n";
	cudaDeviceReset();
	exit(1);
}


typedef unsigned char BYTE;             // 8-bit byte
typedef unsigned int  WORD;             // 32-bit word, change to "long" for 16-bit machines

typedef struct {
	BYTE data[64];
	WORD datalen;
	unsigned long long bitlen;
	WORD state[8];
} SHA256_CTX;

#define ROTLEFT(a,b) (((a) << (b)) | ((a) >> (32-(b))))
#define ROTRIGHT(a,b) (((a) >> (b)) | ((a) << (32-(b))))

#define CH(x,y,z) (((x) & (y)) ^ (~(x) & (z)))
#define MAJ(x,y,z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
#define EP0(x) (ROTRIGHT(x,2) ^ ROTRIGHT(x,13) ^ ROTRIGHT(x,22))
#define EP1(x) (ROTRIGHT(x,6) ^ ROTRIGHT(x,11) ^ ROTRIGHT(x,25))
#define SIG0(x) (ROTRIGHT(x,7) ^ ROTRIGHT(x,18) ^ ((x) >> 3))
#define SIG1(x) (ROTRIGHT(x,17) ^ ROTRIGHT(x,19) ^ ((x) >> 10))

/**************************** VARIABLES *****************************/
__device__ static const WORD k[64] = {
	0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
	0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
	0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
	0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
	0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
	0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
	0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
	0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
};

/*********************** FUNCTION DEFINITIONS ***********************/
__device__ void sha256_transform(SHA256_CTX *ctx, BYTE data[])
{
	WORD a, b, c, d, e, f, g, h, i, j, t1, t2, m[64];

	for (i = 0, j = 0; i < 16; ++i, j += 4)
		m[i] = (data[j] << 24) | (data[j + 1] << 16) | (data[j + 2] << 8) | (data[j + 3]);
	for ( ; i < 64; ++i)
		m[i] = SIG1(m[i - 2]) + m[i - 7] + SIG0(m[i - 15]) + m[i - 16];

	a = ctx->state[0];
	b = ctx->state[1];
	c = ctx->state[2];
	d = ctx->state[3];
	e = ctx->state[4];
	f = ctx->state[5];
	g = ctx->state[6];
	h = ctx->state[7];

	for (i = 0; i < 64; ++i) {
		t1 = h + EP1(e) + CH(e,f,g) + k[i] + m[i];
		t2 = EP0(a) + MAJ(a,b,c);
		h = g;
		g = f;
		f = e;
		e = d + t1;
		d = c;
		c = b;
		b = a;
		a = t1 + t2;
	}

	ctx->state[0] += a;
	ctx->state[1] += b;
	ctx->state[2] += c;
	ctx->state[3] += d;
	ctx->state[4] += e;
	ctx->state[5] += f;
	ctx->state[6] += g;
	ctx->state[7] += h;
}

__device__ void sha256_init(SHA256_CTX *ctx)
{
	ctx->datalen = 0;
	ctx->bitlen = 0;
	ctx->state[0] = 0x6a09e667;
	ctx->state[1] = 0xbb67ae85;
	ctx->state[2] = 0x3c6ef372;
	ctx->state[3] = 0xa54ff53a;
	ctx->state[4] = 0x510e527f;
	ctx->state[5] = 0x9b05688c;
	ctx->state[6] = 0x1f83d9ab;
	ctx->state[7] = 0x5be0cd19;
}

__device__ void sha256_update(SHA256_CTX *ctx, const BYTE data[], size_t len)
{
	WORD i;

	for (i = 0; i < len; ++i) {
		ctx->data[ctx->datalen] = data[i];
		ctx->datalen++;
		if (ctx->datalen == 64) {
			sha256_transform(ctx, ctx->data);
			ctx->bitlen += 512;
			ctx->datalen = 0;
		}
	}
}

__device__ void sha256_final(SHA256_CTX *ctx, BYTE hash[])
{
	WORD i;

	i = ctx->datalen;

	// Pad whatever data is left in the buffer.
	if (ctx->datalen < 56) {
		ctx->data[i++] = 0x80;
		while (i < 56)
			ctx->data[i++] = 0x00;
	}
	else {
		ctx->data[i++] = 0x80;
		while (i < 64)
			ctx->data[i++] = 0x00;
		sha256_transform(ctx, ctx->data);
		memset(ctx->data, 0, 56);
	}

	// Append to the padding the total message's length in bits and transform.
	ctx->bitlen += ctx->datalen * 8;
	ctx->data[63] = ctx->bitlen;
	ctx->data[62] = ctx->bitlen >> 8;
	ctx->data[61] = ctx->bitlen >> 16;
	ctx->data[60] = ctx->bitlen >> 24;
	ctx->data[59] = ctx->bitlen >> 32;
	ctx->data[58] = ctx->bitlen >> 40;
	ctx->data[57] = ctx->bitlen >> 48;
	ctx->data[56] = ctx->bitlen >> 56;
	sha256_transform(ctx, ctx->data);

	// Since this implementation uses little endian byte ordering and SHA uses big endian,
	// reverse all the bytes when copying the final state to the output hash.
	for (i = 0; i < 4; ++i) {
		hash[i]      = (ctx->state[0] >> (24 - i * 8)) & 0x000000ff;
		hash[i + 4]  = (ctx->state[1] >> (24 - i * 8)) & 0x000000ff;
		hash[i + 8]  = (ctx->state[2] >> (24 - i * 8)) & 0x000000ff;
		hash[i + 12] = (ctx->state[3] >> (24 - i * 8)) & 0x000000ff;
		hash[i + 16] = (ctx->state[4] >> (24 - i * 8)) & 0x000000ff;
		hash[i + 20] = (ctx->state[5] >> (24 - i * 8)) & 0x000000ff;
		hash[i + 24] = (ctx->state[6] >> (24 - i * 8)) & 0x000000ff;
		hash[i + 28] = (ctx->state[7] >> (24 - i * 8)) & 0x000000ff;
	}
}

__device__ int	ft_memcmp(const void *s1, const void *s2, size_t n)
{
	const unsigned char		*str1;
	const unsigned char		*str2;

	if (s1 == s2 || n == 0)
		return (0);
	str1 = (const unsigned char *)s1;
	str2 = (const unsigned char *)s2;
	while (n--)
	{
		if (*str1 != *str2)
			return (*str1 - *str2);
		if (n)
		{
			str1++;
			str2++;
		}
	}
	return (0);
}

__global__ void	brute()
{
	unsigned char	key[16];
	unsigned char	hash[64];

	// MASK 1

	// key[0] = blockIdx.x;
	// key[1] = blockIdx.x;
	// key[2] = blockIdx.x;
	// key[3] = blockIdx.x;
	// key[4] = blockIdx.y;
	// key[5] = blockIdx.y;
	// key[6] = blockIdx.y;
	// key[7] = blockIdx.y;
	// key[8] = blockIdx.z;
	// key[9] = blockIdx.z;
	// key[10] = blockIdx.z;
	// key[11] = blockIdx.z;
	// key[12] = threadIdx.x;
	// key[13] = threadIdx.x;
	// key[14] = threadIdx.x;
	// key[15] = threadIdx.x;


key[0] = 0xf0;
key[1] = 0x8f;
key[2] = threadIdx.x;
key[3] = 0x46;
key[4] = 0x4a;
key[5] = 0xea;
key[6] = blockIdx.z;
key[7] = 0xa;
key[8] = 0xff;
key[9] = 0xf7;
key[10] = blockIdx.y;
key[11] = 0xfe;
key[12] = 0xe1;
key[13] = 0xe7;
key[14] = 0x0;
key[15] = 0xbf;


	SHA256_CTX ctx;

	sha256_init(&ctx);
	sha256_update(&ctx, key, 16);
	sha256_final(&ctx, hash);

	if (!ft_memcmp(hash, KNOWN_HASH, 32)) {
		printf("Found key: 0x%x: 0x%x, 0x%x: 0x%x, 0x%x: 0x%x, 0x%x: 0x%x,\n",
			0x08, key[6], 0x70, key[10], 0xe5, key[2], 0,0
		);
		// printf("Found key: 0x%x, 0x%x, 0x%x, 0x%x,\n",
		// 	key[0], key[2], key[6], key[14]
		// );
	}
	
}

int main(void)
{
	clock_t			start;
	clock_t			stop;

	dim3	blocks(256, 256, 256);
	dim3	threads(256);

	start = clock();

	brute<<<blocks, threads>>>();
	CHECK(cudaGetLastError());
	CHECK(cudaDeviceSynchronize());

	stop = clock();
	std::cerr << "Took: " << ((double)(stop - start)) / CLOCKS_PER_SEC << "\n";

	return (0);
}