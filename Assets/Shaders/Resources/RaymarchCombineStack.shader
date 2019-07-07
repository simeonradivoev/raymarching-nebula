// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/Raymarch Combine"
{
	HLSLINCLUDE

	#include "PostProcessing/Shaders/StdLib.hlsl"

	TEXTURE2D_SAMPLER2D(_MainTex,sampler_MainTex);
	TEXTURE2D_SAMPLER2D(_Clouds,sampler_Clouds);
	TEXTURE2D_SAMPLER2D(LowResDepthTexture,samplerLowResDepthTexture);
	float DepthThreshold;

	TEXTURE2D_SAMPLER2D(_CameraDepthTexture,sampler_CameraDepthTexture);
	float4 _CameraDepthTexture_TexelSize;

	inline void UpdateNearestSample(inout float MinDist,
		inout float2 NearestUV,
		float Z,
		float2 UV,
		float ZFull
	)
	{
		float Dist = abs(Z - ZFull);
		if (Dist < MinDist)
		{
			MinDist = Dist;
			NearestUV = UV;
		}
	}

	inline float4 GetNearestDepthSample(float2 uv)
	{
		//read full resolution depth
		float ZFull = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,sampler_CameraDepthTexture, uv));

		//find low res depth texture texel size
		const float2 lowResTexelSize = 2.0 * _CameraDepthTexture_TexelSize.xy;
		const float depthTreshold = DepthThreshold;

		float2 lowResUV = uv;

		float MinDist = 1.e8f;

		float2 UV00 = lowResUV - 0.5 * lowResTexelSize;
		float2 NearestUV = UV00;
		float Z00 = Linear01Depth(SAMPLE_DEPTH_TEXTURE(LowResDepthTexture,samplerLowResDepthTexture, UV00));
		UpdateNearestSample(MinDist, NearestUV, Z00, UV00, ZFull);

		float2 UV10 = float2(UV00.x + lowResTexelSize.x, UV00.y);
		float Z10 = Linear01Depth(SAMPLE_DEPTH_TEXTURE(LowResDepthTexture,samplerLowResDepthTexture, UV10));
		UpdateNearestSample(MinDist, NearestUV, Z10, UV10, ZFull);

		float2 UV01 = float2(UV00.x, UV00.y + lowResTexelSize.y);
		float Z01 = Linear01Depth(SAMPLE_DEPTH_TEXTURE(LowResDepthTexture,samplerLowResDepthTexture, UV01));
		UpdateNearestSample(MinDist, NearestUV, Z01, UV01, ZFull);

		float2 UV11 = UV00 + lowResTexelSize;
		float Z11 = Linear01Depth(SAMPLE_DEPTH_TEXTURE(LowResDepthTexture,samplerLowResDepthTexture, UV11));
		UpdateNearestSample(MinDist, NearestUV, Z11, UV11, ZFull);

		float4 fogSample = float4(0, 0, 0, 0);

		if (abs(Z00 - ZFull) < depthTreshold &&
			abs(Z10 - ZFull) < depthTreshold &&
			abs(Z01 - ZFull) < depthTreshold &&
			abs(Z11 - ZFull) < depthTreshold)
		{
			fogSample = SAMPLE_TEXTURE2D_LOD(_Clouds,sampler_Clouds, lowResUV,0);
		}
		else
		{
			fogSample = SAMPLE_TEXTURE2D_LOD(_Clouds,sampler_Clouds, NearestUV,0);
		}

		return fogSample;
	}

	float4 Frag(VaryingsDefault i) : SV_Target
	{
		float4 clouds = GetNearestDepthSample(i.texcoord);
		float4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.texcoord);
		return lerp(col, clouds, clouds.a);
	}

	ENDHLSL

	SubShader
	{
		Cull Off ZWrite Off ZTest Always

		Pass
        {
            HLSLPROGRAM

                #pragma vertex VertDefault
                #pragma fragment Frag

            ENDHLSL
        }
	}
}
