// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/Downscale Depth" {

	HLSLINCLUDE

	#include "PostProcessing/Shaders/StdLib.hlsl"

	struct v2f
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
	};

	TEXTURE2D_SAMPLER2D(_CameraDepthTexture,sampler_CameraDepthTexture);
	float4 _CameraDepthTexture_TexelSize; // (1.0/width, 1.0/height, width, height)

	float4 Frag(VaryingsDefault i) : SV_Target
	{
		float2 texelSize = 0.5 * _CameraDepthTexture_TexelSize.xy;

		float depth1 = SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture, float2(i.texcoord + float2(-1,-1)*texelSize)).r;
		float depth2 = SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture, float2(i.texcoord + float2(-1,1)*texelSize)).r;
		float depth3 = SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture, float2(i.texcoord + float2(1,-1)*texelSize)).r;
		float depth4 = SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture, float2(i.texcoord + float2(1,1)*texelSize)).r;

		float result = min(depth1, min(depth2, min(depth3, depth4)));

		return result;
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
