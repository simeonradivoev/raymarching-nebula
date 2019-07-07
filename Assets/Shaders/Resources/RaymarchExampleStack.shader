Shader "Hidden/Raymarch"
{
	HLSLINCLUDE

	#include "PostProcessing/Shaders/StdLib.hlsl"

	//Unity Global
	TEXTURE2D_SAMPLER2D(LowResDepthTexture, samplerLowResDepthTexture);
	float4 LowResDepthTexture_TexelSize;

	// Global properties
	TEXTURE2D_SAMPLER2D(_NoiseOffsets, sampler_NoiseOffsets);
	float4x4 InverseViewMatrix;
	float4x4 InverseProjectionMatrix;

	// Local properties
	int _Iterations;
	float4 FogColor;
	float MaxViewDistance;
	float Density;
	float ScatteringCoeff;
	float ExtinctionCoeff;
	float3 LightPos;
	float FalloffPower;
	float NoiseSize;
	float NoiseAmount;

	// Shamelessly stolen from https://www.shadertoy.com/view/4sfGzS
	float noise(float3 x) { x *= 4.0; float3 p = floor(x); float3 f = frac(x); f = f*f*(3.0 - 2.0*f); float2 uv = (p.xy + float2(37.0, 17.0)*p.z) + f.xy; float2 rg = SAMPLE_TEXTURE2D(_NoiseOffsets,sampler_NoiseOffsets, (uv + 0.5) / 256.0).yx; return lerp(rg.x, rg.y, f.z); }
	float fbm(float3 pos, int octaves) { float f = 0.; for (int i = 0; i < octaves; i++) { f += noise(pos) / pow(2, i + 1); pos *= 2.01; } f /= 1 - 1 / pow(2, octaves + 1); return f; }

	float distFunc(float3 pos)
	{
		return length(pos) - 2;
	}

	#define GRID_SIZE 1.0
	#define GRID_SIZE_SQR_RCP (1.0/(GRID_SIZE*GRID_SIZE))

	struct Varyings
	{
		float4 vertex : SV_POSITION;
		float2 texcoord : TEXCOORD0;
		float2 texcoordStereo : TEXCOORD1;
		float4 cameraRay : TEXCOORD2;
	#if STEREO_INSTANCING_ENABLED
		uint stereoTargetEyeIndex : SV_RenderTargetArrayIndex;
	#endif
	};

	Varyings Vert(AttributesDefault v)
	{
		Varyings o;
		o.vertex = float4(v.vertex.xy, 0.0, 1.0);
		o.texcoord = TransformTriangleVertexToUV(v.vertex.xy);

	#if UNITY_UV_STARTS_AT_TOP
		o.texcoord = o.texcoord * float2(1.0, -1.0) + float2(0.0, 1.0);
	#endif

		o.texcoordStereo = TransformStereoScreenSpaceTex(o.texcoord, 1.0);

		float4 clipPos = float4(o.texcoord * 2.0 - 1.0, 1.0, 1.0);

		float4 cameraRay = mul(InverseProjectionMatrix, clipPos);
		o.cameraRay = cameraRay / cameraRay.w;

		return o;
	}

	float4 Frag(Varyings i) : SV_Target
	{
		float depth = SAMPLE_DEPTH_TEXTURE(LowResDepthTexture,samplerLowResDepthTexture, i.texcoord);

		//linearise depth		
		float lindepth = Linear01Depth(depth);

		float4 viewPos = float4(i.cameraRay.xyz * lindepth, 1);
		float3 worldPos = mul(InverseViewMatrix, viewPos).xyz;

		float3 pos = _WorldSpaceCameraPos.xyz;
		float3 rayDir = normalize(worldPos - pos);
		float rayDistance = length(worldPos - pos);

		//cap raymarching distance				
		rayDistance = min(rayDistance, MaxViewDistance);

		float stepSize = rayDistance * (1.0 / _Iterations);

		float3 currentPos = pos;

		float2 interleavedPos = fmod(float2(i.vertex.x, LowResDepthTexture_TexelSize.w - i.vertex.y), GRID_SIZE);
		float rayStartOffset = (interleavedPos.y * GRID_SIZE + interleavedPos.x) * (stepSize * GRID_SIZE_SQR_RCP);
		//currentPos += rayStartOffset * rayDir.xyz;
		// For each iteration, we read from our noise function the density of our current position, and adds it to this density variable.
		float4 result = 0;

		float transmittance = 1;

		for (float i = 0; i < _Iterations; i++)
		{
			float noiseValue = 1;
			if(NoiseAmount > 0)
				noiseValue = lerp(1,saturate( 2 * noise(currentPos * NoiseSize)), NoiseAmount);

			float scattering = ScatteringCoeff * Density;
			float extinction = ExtinctionCoeff * Density;
			float3 newPos = currentPos + rayDir * stepSize;

			transmittance *= exp(-extinction * stepSize);
			float dCur = length(LightPos - currentPos);
			result += (Density / pow(dCur, FalloffPower)) * stepSize * extinction * ScatteringCoeff * noiseValue * FogColor;
			// And then we move one step further away from the camera.
			currentPos = newPos;
		}

		// And here i just melted all our variables together with random numbers until I had something that looked good.
		// You can try playing around with them too.
		float4 color = result;

		return color;
	}
	
	ENDHLSL

	SubShader
	{
		Cull Off ZWrite Off ZTest Always

		Pass
        {
            HLSLPROGRAM

                #pragma vertex Vert
                #pragma fragment Frag

            ENDHLSL
        }
	}
}