Shader "URP/ShaderBook/Chapter 11/ScrollingBackground"
{
    Properties
    {
        _BackLayer("BackLayer(RGB)",2D) = "white"{}
        _FrontLayer("FrontLayer(RGB)",2D) = "white"{}
        _ScrollX("BackLayerSpeed",float) = 1.0
        _Scroll2X("FrontLayerSpeed",float) = 1.0
        _Multiplier("LayerMultiplier",float) = 1.0
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType"="Opaque" "Queue" = "Geometry"}
        LOD 100

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            
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
                float4 uv : TEXCOORD0;
            };

            TEXTURE2D(_BackLayer);SAMPLER(sampler_BackLayer);
            TEXTURE2D(_FrontLayer);SAMPLER(sampler_FrontLayer);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BackLayer_ST;
                float4 _FrontLayer_ST;
                float  _ScrollX;
                float  _Scroll2X;
                float _Multiplier;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv.xy = TRANSFORM_TEX(v.texcoord,_BackLayer) + frac(float2(_ScrollX,0.0) * _Time.y);
                o.uv.zw = TRANSFORM_TEX(v.texcoord,_FrontLayer) + frac(float2(_Scroll2X,0.0) * _Time.y);
                
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                half4 firstLayer = SAMPLE_TEXTURE2D(_BackLayer,sampler_BackLayer,i.uv.xy);
                half4 SecondLayer = SAMPLE_TEXTURE2D(_FrontLayer,sampler_FrontLayer,i.uv.zw);

                half4 c = lerp(firstLayer,SecondLayer,SecondLayer.a);//使用前景图片的Alpha通道作为遮罩，即白色的地方显示第二个参数贴图，黑色的地方显示第一个参数贴图

                FinalColor =  half4(c.rgb * _Multiplier , 1.0);
                
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
