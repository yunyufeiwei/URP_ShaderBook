Shader "URP/Chapte 12/BrightnessSaturationAndContrast"
{
    Properties
    {
        //后处理shader的主纹理必须使用_MainTex
        _MainTex ("MainTex", 2D) = "white" {}

        _Brightness("Brightness" , float ) = 1
        _Saturation("Saturation" , float ) = 1
        _Contrast("Contrast",float ) = 1
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry"  }
        LOD 100

        Pass
        {
            NAME"BrightnessSaturationAndContrast"
            Tags{"LightMode" = "UniversalForward"}  
            ZTest always
            Cull off    
            ZWrite off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
            };

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float  _Brightness;
                float  _Saturation;
                float  _Contrast;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                //得到从camera屏幕图像，在shader中采样后计算
                half4 renderTex = SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , i.uv);

                //计算图像亮度
                FinalColor = half4(renderTex.rgb * _Brightness , 1.0);

                half luminance = 0.125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;
                half3 luminanceColor = half3(luminance,luminance,luminance);
                FinalColor = half4(lerp(luminanceColor , FinalColor.rgb , _Saturation) , 1.0);

                half3 avgColor = half3(0.5,0.5,0.5);
                FinalColor = half4(lerp(avgColor , FinalColor.rgb , _Contrast) , 1.0);

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
