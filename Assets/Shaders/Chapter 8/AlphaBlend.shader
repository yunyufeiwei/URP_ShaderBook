Shader "URP/Chapter 8/AlphaBlend"
{
    Properties
    {
        [Header(BlendMode)]
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcFactor("SrcFactor",int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]_DstFactor("DstFactor",int) = 0

        [Space(20)]
        _Color("Color" , Color) = (1,1,1,1)
        _BaseMap("BaseMap" , 2D) = "white"{}
        _AlphaScale("_AlphaScale" , Range(0 ,1)) = 1
    }

    SubShader 
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent" }
        
        pass
        {
            Tags{"LightMode" = "UniversalForward"}

            ZWrite Off
            Blend [_SrcFactor] [_DstFactor]

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
                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                
                o.uv = TRANSFORM_TEX(v.texcoord , _BaseMap);

                return o;
            }

            half4 frag(Varyings i) : SV_TARGET
            {
                half4 FinalColor;

                Light light = GetMainLight();
                half4 lightColor = half4(light.color * light.distanceAttenuation , 1.0);
                half3 worldLightDir = light.direction;

                half3 worldNormal = normalize(i.normalWS);

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap , sampler_BaseMap , i.uv);

                half4 diffuse = lightColor * _Color * baseMap * max(0 , dot(worldNormal , worldLightDir));

                FinalColor = diffuse;

                return half4(FinalColor.rgb , baseMap.a * _AlphaScale);                
            }
            ENDHLSL
        }
    }
}
