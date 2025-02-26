Shader "URP/Chapter 6/Blinn_Phong"
{
    Properties
    {
        _DiffuseColor("DiffuseColor", Color) = (1,1,1,1)
        _SpecularColor("SpecularColor",Color) = (1,1,1,1)
        [PowerSlider(20)]_SpeculsrPower("SpecularPower",Range(1,50)) = 8
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry"}
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
                float4 color        : COLOR;
                float2 uv           : TEXCOORD0;
                float3 positionWS   : TEXCOORD1;
                float3 normalWS     : TEXCOORD2;
                float3 viewDirWS    : TEXCOORD3;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _DiffuseColor;
                float4 _SpecularColor;
                float  _SpeculsrPower;
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
                // half3 reflectDir = normalize(reflect(-worldLightDir , worldNormal));
                half3 halfDir = SafeNormalize(worldLightDir+worldViewDir);

                half4 diffuse = lightColor * _DiffuseColor * saturate(dot(worldLightDir,worldNormal));

                //phong
                half4 specluar = lightColor * _SpecularColor * pow(saturate(dot(worldNormal , halfDir)) , _SpeculsrPower);

                FinalColor = diffuse + specluar;

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
