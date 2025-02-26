Shader "URP/Chapter 13/MotionBlurWithDepthTexture"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurSize("BlurSize" , float) = 1.0
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry"}

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        struct Attributes
		{
			float4 positionOS 	: POSITION;
			float2 texcoord 	: TEXCOORD;
		};

        struct Varyings
        {
            float4 positionHCS  : POSITION;
            float2 uv           : TEXCOORD;
            float2 uv_depth     : TEXCOORD1;
        };

        TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
        TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
        CBUFFER_START(UnityPerMaterial)
            half4 _MainTex_TexelSize;
            float4x4 _CurrentViewProjectionInverseMatrix;
            float4x4 _PreviousViewProjectionMatrix;
            half _BlurSize;
        CBUFFER_END

        Varyings vert(Attributes v)
        {
            Varyings o = (Varyings)0;
            o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
            o.uv = v.texcoord;
            o.uv_depth = v.texcoord;

            //处理平台差异化导致的图像问题  direct X    OpenGL   ,使用1- 的计算将屏幕空间进行转换
            #if UNITY_UV_STARTS_AT_TOP
            if(_MainTex_TexelSize.y < 0)
            {
                o.uv_depth.y = 1 - o.uv_depth.y;
            }
            #endif
            return o;
        }

        half4 frag(Varyings i) : SV_TARGET
        {
            //采样深度纹理
            float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture , sampler_CameraDepthTexture , i.uv_depth);

            //H是该像素在-1到1范围内的视口位置。
            float4 H = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, d * 2 - 1, 1);
            //变换由视图-投影逆。
            float4 D = mul(_CurrentViewProjectionInverseMatrix, H);
            //除以w得到世界位置。
            float4 worldPos = D / D.w;

            //当前窗口的位置
            float4 currentPos = H;
            //使用世界位置，并通过前面的视图投影矩阵进行转换
            float4 previousPos = mul(_PreviousViewProjectionMatrix, worldPos);
            //转换为非齐次点[-1,1]除以w。
            previousPos /= previousPos.w;

            //使用该帧的位置和最后一帧的位置来计算像素速度。
            float2 velocity = (currentPos.xy - previousPos.xy)/2.0f;

            float2 uv = i.uv;
			float4 c = SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , uv);
			uv += velocity * _BlurSize;
			for (int it = 1; it < 3; it++, uv += velocity * _BlurSize) 
            {
				float4 currentColor = SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , uv);
				c += currentColor;
			}
			c /= 3;
			
			return half4(c.rgb, 1.0);
        }
        ENDHLSL

        Pass 
        {   
            NAME "MotionBlurWithDepthTexture"
			ZTest Always Cull Off ZWrite Off
			HLSLPROGRAM  
			#pragma vertex vert  
			#pragma fragment frag  
			ENDHLSL  
		}        
    }
}
