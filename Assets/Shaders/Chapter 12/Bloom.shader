Shader "URP/Chapte 12/Bloom"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_blurSize ("BlurSize", Range(0,5)) = 2
		_LuminanceThreshold ("LuminanceThreshold", Range(0,1)) = 0.5
	}
	SubShader
	{
		Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry"}
		Cull Off
		ZWrite Off
		ZTest Always
		
		HLSLINCLUDE
		
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		
		struct Attributes
		{
			float4 positionOS: POSITION;
			float2 uv: TEXCOORD0;
		};
		
		struct Varyings_Extract
		{
			float4 vertex: SV_POSITION;
			float2 uv: TEXCOORD0;
		};

		struct Varyings_Bloom
		{
			float4 vertex: SV_POSITION;
			float4 uv: TEXCOORD0;
		};
		
		CBUFFER_START(UnityPerMaterial)
			float4 _MainTex_TexelSize;
			half _LuminanceThreshold;
			half _BlurSize;
		CBUFFER_END
		
		TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
		TEXTURE2D(_BloomTex);    SAMPLER(sampler_BloomTex);

		float2 CorrectUV(in float2 uv, in float4 texelSize)
		{
			float2 result = uv;
			
			#if UNITY_UV_STARTS_AT_TOP
				if(texelSize.y < 0.0)
				result.y = 1.0 - uv.y;
			#endif

			return result;
		}

		float CustomLuminance(in float3 c)
		{
			//根据人眼对颜色的敏感度，可以看见对绿色是最敏感的
			return 0.2125 * c.r + 0.7154 * c.g + 0.0721 * c.b;
		}
		
		Varyings_Extract vertExtract(Attributes input)
		{
			Varyings_Extract output = (Varyings_Extract)0;
			
			output.vertex = TransformObjectToHClip(input.positionOS.xyz);
			output.uv = CorrectUV(input.uv,_MainTex_TexelSize);
			
			return output;
		}
		
		half4 fragExtract(Varyings_Extract input): SV_Target
		{
			half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
			half val = clamp(CustomLuminance(col.rgb) - _LuminanceThreshold, 0.0, 1.0);
			return col * val;
		}

		
		
		Varyings_Bloom vertBloom(Attributes input)
		{
			Varyings_Bloom output = (Varyings_Bloom)0;
			
			output.vertex = TransformObjectToHClip(input.positionOS.xyz);
			output.uv.xy = input.uv;
			output.uv.zw = CorrectUV(input.uv, _MainTex_TexelSize);
			
			return output;
		}
		
		half4 fragBloom(Varyings_Bloom input): SV_Target
		{
			
			return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv.xy) + SAMPLE_TEXTURE2D(_BloomTex, sampler_BloomTex, input.uv.zw);
		}
		
		ENDHLSL

		pass
		{
			HLSLPROGRAM
			#pragma vertex vertExtract  
			#pragma fragment fragExtract
			ENDHLSL
		}  

		UsePass "URP/Chapter 12/GaussianBlur/GAUSSIAN_BLUR_HORIZONTAL"
		UsePass "URP/Chapter 12/GaussianBlur/GAUSSIAN_BLUR_VERTICAL"
		// UsePass "RoadOfShader/Gaussian Blur/GAUSSIAN_HOR"
		// UsePass "RoadOfShader/Gaussian Blur/GAUSSIAN_VERT"

		pass
		{
			HLSLPROGRAM
			#pragma vertex vertBloom  
			#pragma fragment fragBloom
			ENDHLSL
		}  
	}
}
