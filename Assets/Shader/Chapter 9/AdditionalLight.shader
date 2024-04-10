Shader "URP/ShaderBook/Chapter 9/AdditionalLight"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _SpecularColor("SpecularColor",Color) = (1,1,1,1)
        [PowerSlider(20)]_SpecularPower("SpecularPower",Range(8,255)) = 20
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
                float3 viewDirWS    : TEXCOORD3;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _SpecularColor;
                float  _SpecularPower;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.viewDirWS = GetWorldSpaceViewDir(o.positionWS);
                
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                Light light = GetMainLight();
                half3 worldLightDir = light.direction;
                half4 lightColor = half4(light.color * light.distanceAttenuation , 1.0);

                half3 worldNormal = normalize(i.normalWS);
                half3 worldViewDir = normalize(i.viewDirWS);
                half3 halfDir = normalize(worldLightDir+worldViewDir);

                half3 diffuse = lightColor.rgb * _Color.rgb * max(0.0,dot(worldNormal,worldLightDir));
                half3 specular = lightColor.rgb * _SpecularColor * pow(max(0.0,dot(worldNormal,halfDir)),_SpecularPower);

                //支持额外光源
                int additionalLightCount = GetAdditionalLightsCount();  //获取额外光源数量
                for(int j = 0;j<additionalLightCount;j++)
                {
                    light = GetAdditionalLight(j,i.positionWS);
                    half3 attenuatedLightColor = light.color * light.distanceAttenuation;
                    diffuse += LightingLambert(light.color,light.direction,worldNormal);
                    specular += LightingSpecular(light.color,light.direction,worldNormal,worldViewDir,_SpecularColor,_SpecularPower);
                }
                
                FinalColor = half4(diffuse + specular,1.0);
                
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
