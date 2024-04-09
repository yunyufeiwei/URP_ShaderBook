Shader "URP/ShaderBook/Chapter 8/BlendOperations0"
{
    Properties
    {
        _Color("Color",color) = (1,1,1,1)
        _BaseMap("BaseMap",2D) = "white"{}
        _AlphaScale("AlphaScale",Range(0,1)) = 1
        
        [Header(BlendMode)]
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcFactor("SrcFactor",int) = 5
        [Enum(UnityEngine.Rendering.BlendMode)]_DstFactor("DstFactor",int) = 10
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType"="Transparent" "Queue" = "Transparent"}
        LOD 100

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            
            ZWrite Off
            Blend [_SrcFactor][_DstFactor]
            
            //正常，透明度混合
            //Blend SrcAlpha OneMinusSrcAlpha
            
            //柔和相加
            //Blend OneMinusDstColor Zero
            
            //正片叠底
            //Blend DstColor Zero
            
            //两倍相乘
            //Blend DstColor SrcColor
            
            //变暗
            //BlendOp Min
            //Blend One One
            
            //变亮
            //BlendOp Max
            //Blend One One
            
            //滤色
            //Blend OneMinusDstColor One
            //效果等同
            //Blend One OneMinusSrcColor
            
            //线性减淡
            //Blend One One
            
            HLSLPROGRAM
            #pragma vertex vert 
            #pragma fragment frag 

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

             struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
            };
            
            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _BaseMap_ST;
                float  _AlphaScale;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                return o;
            }

            half4 frag(Varyings i) : SV_TARGET
            {
                half4 FinalColor;

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap , sampler_BaseMap , i.uv);

                FinalColor = half4(baseMap.rgb * _Color.rgb , baseMap.a * _AlphaScale);
                
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
