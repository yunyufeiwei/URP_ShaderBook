Shader "URP/Chapter 7/RanpTexture"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _RampTex ("RampTex", 2D) = "white" {}
        _SpecularColor("SpecularColor",Color) = (1,1,1,1)
        [PowerSlider(20)]_SpecularPower("SpecularPower",Range(1,255)) =  8
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
                float2 uv           : TEXCOORD0;
                float3 positionWS   : TEXCOORD1;
                float3 normalWS     : TEXCOORD2;
                float3 viewDirWS    : TEXCOORD3;
            };

           TEXTURE2D(_RampTex);SAMPLER(sampler_RampTex);

           CBUFFER_START(UnityPerMaterial)
                float4 _RampTex_ST;
                float4 _Color;
                float4 _SpecularColor;
                float  _SpecularPower;
           CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionWS  = TransformObjectToWorld(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.viewDirWS = GetWorldSpaceViewDir(o.positionWS);

                o.uv = TRANSFORM_TEX(v.texcoord, _RampTex);

                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                Light light = GetMainLight();
                half4 lightColor = half4(light.color * light.distanceAttenuation , 1.0);
                half3 worldLightDir = light.direction;

                half3 worldNormal = normalize(i.normalWS);
                half3 worldViewDir = normalize(i.viewDirWS);
                half3 halfDir = normalize(worldLightDir + worldViewDir);

                half  halfLambert = dot(worldNormal,worldLightDir) * 0.5 + 0.5;
                half4 RampTex = SAMPLE_TEXTURE2D(_RampTex , sampler_RampTex , halfLambert);

                half4 diffuse = lightColor * _Color * RampTex;
                half4 specular = lightColor * _SpecularColor * pow(max(0.0 , dot(worldNormal,halfDir)),_SpecularPower);

                FinalColor = diffuse + specular;

                return halfLambert;
            }
            ENDHLSL
        }
    }
}
