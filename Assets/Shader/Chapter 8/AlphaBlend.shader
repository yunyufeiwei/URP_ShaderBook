Shader "URP/ShaderBook/Chapter 8/AlphaBlend"
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
//            Blend SrcAlpha OneMinusSrcAlpha
            Blend [_SrcFactor][_DstFactor]
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
                float3 normalOS     : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 positionWS   : TEXCOORD1;
                float3 normalWS     : TEXCOORD2;
            };

           TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _BaseMap_ST;
                float  _AlphaScale;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o=(Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);

                o.uv = TRANSFORM_TEX(v.texcoord,_BaseMap);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;
                Light light = GetMainLight();
                half3 worldLightDir = light.direction;
                half4 lightColor = half4(light.color * light.distanceAttenuation , 1.0);

                half3 worldNormal = normalize(i.normalWS);

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,i.uv);

                half4 diffuse = lightColor * _Color * baseMap * max(0.0,dot(worldLightDir,worldNormal) * 0.5 + 0.5);

                FinalColor = diffuse;
                
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
