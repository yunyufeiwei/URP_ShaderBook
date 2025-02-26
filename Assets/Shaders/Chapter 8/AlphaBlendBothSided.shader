Shader "URP/Chapter 8/AlphaBlendBothSided"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode("CullMode" , int) = 0
        _Color("Color" , Color) = (1,1,1,1)
        _BaseMap("BaseMap" , 2D) = "white"{}
        _AlphaScale("_AlphaScale" , Range(0 ,1)) = 1
    }

    SubShader 
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent" }

        //该Pass只渲染背面        
        pass
        {
            Tags{"LightMode" = "UniversalForward"}
            //剔除面向摄像机的渲染
            Cull [_CullMode]

            ZWrite On
            Blend SrcAlpha OneMinusSrcAlpha            

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
                o.normalWS = TransformObjectToWorldNormal(v.normalOS.xyz);

                o.uv = TRANSFORM_TEX(v.texcoord.xy , _BaseMap);

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

                half4 diffuse = lightColor * _Color * baseMap * max(0 , dot(worldNormal , worldLightDir) * 0.5 + 0.5);

                FinalColor =  diffuse;

                return half4(FinalColor.rgb , baseMap.a * _AlphaScale);
            }
            ENDHLSL
        }
    }
}
