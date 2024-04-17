Shader "URP/ShaderBook/Chapter 11/ImageSequenceAnimation"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _BaseMap("BaseMap",2D) = "white"{}
        _HorizontalAmount("HorizontalAmount",float) = 8     //定义水平序列帧数量
        _VerticalAmount("VerticalAmount",float) = 8 //定义垂直序列帧的数量
        _Speed("Speed",float) = 1
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType"="Transparent" "Queue" = "Transparent"}
        LOD 100

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
                float2 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _BaseMap_ST;
                float  _HorizontalAmount;
                float  _VerticalAmount;
                float  _Speed;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                // o.uv = TRANSFORM_TEX(v.texcoord,_BaseMap);
                o.uv = v.texcoord;
                
                return o;
            }

             half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                float time = floor(_Time.y * _Speed);
                float row = floor(time / _HorizontalAmount);
                float column = time -row * _VerticalAmount;

                // half2 uv=float2(i.uv.x/_HorizontalAmount,i.uv.y/_VerticalAmount);
                // uv.x +=column/_HorizontalAmount;
                // uv.y-=row/_VerticalAmount;
                //通过向下取整之后重新构建采样的uv
                half2 uv = i.uv + half2(column,-row);
                uv.x /= _HorizontalAmount;
                uv.y /= _VerticalAmount;
                
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,uv);

                FinalColor = baseMap * _Color;
                
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
