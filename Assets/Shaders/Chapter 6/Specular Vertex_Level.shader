Shader "URP/Chapter 6/SpecularVertex"
{
    Properties
    {
        _DiffuseColor("DiffuseColor", Color) = (1,1,1,1)
        _SpecularColor("SpecularColor",Color) = (1,1,1,1)
        [PowerSlider(8)]_SpeculsrPower("SpecularPower",Range(0,50)) = 8
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
                
                Light light = GetMainLight();
                half3 worldLightDir = light.direction;
                half4 lightColor = half4(light.color * light.distanceAttenuation , 1.0);

                half3 worldNormal = TransformObjectToWorldNormal(v.normalOS.xyz);

                half3 ViewDirWS = GetWorldSpaceViewDir(o.positionWS);
                half3 reflectDir = normalize(reflect(-worldLightDir , worldNormal));

                half4 diffuse = lightColor * _DiffuseColor * saturate(dot(worldLightDir,worldNormal));

                //phong
                half4 specluar = lightColor * _SpecularColor * pow(saturate(dot(reflectDir , ViewDirWS)) , _SpeculsrPower);

                o.color = diffuse + specluar;
                
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                FinalColor = i.color;

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
