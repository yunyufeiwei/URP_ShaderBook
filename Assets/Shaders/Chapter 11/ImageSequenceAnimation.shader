Shader "URP/Chapte 11/ImageSequenceAnimation"
{
    Properties
    {
        _Color("Color Tint",Color)=(1,1,1,1)
        _BaseMap("Image Sequence ", 2D) = "white" {}
        _HorizontalAmount("Horizontal Amount",float)=4   //定义水平序列帧数量
        _VerticalAmount("Vertical Amount",float)=4       //定义垂直序列帧数量
        _Speed("Speed",range(1,100))=30
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "Queue"="Transparent"  "RenderType"="Transparent"} 

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD;
            };

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _BaseMap_ST;
                float  _HorizontalAmount;
                float  _VerticalAmount;
                float  _Speed;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord , _BaseMap);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;

                float time = floor(_Time.y * _Speed);
                float row = floor(time / _HorizontalAmount);
                float column = time-row * _HorizontalAmount;

                // half2 uv=float2(i.uv.x/_HorizontalAmount,i.uv.y/_VerticalAmount);
                // uv.x +=column/_HorizontalAmount;
                // uv.y-=row/_VerticalAmount;
                half2 uv = i.uv + half2(column,-row);
                uv.x /= _HorizontalAmount;
                uv.y /= _VerticalAmount;

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap , sampler_BaseMap , uv);
                half3 diffuse = baseMap.rgb * _Color.rgb;

                FinalColor = half4(diffuse , baseMap.a);

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
