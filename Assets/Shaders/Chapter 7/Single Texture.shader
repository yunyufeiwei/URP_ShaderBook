Shader "URP/Chapter 7/Single Texture"
{
    Properties
    {
        _Color("Color" , Color) = (1,1,1,1)
        _BaseMap ("BaseMap", 2D) = "white" {}
        _SpecularColor("Specular" , Color) = (1,1,1,1)
        [PowerSlider(50)]_SpecularPower("SpecularPower" , Range(8 , 256)) = 20
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry"}

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
                float3 normalOS     : NORMAL;
                float4 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 positionWS   : TEXCOORD1;
                float3 normalWS     : TEXCOORD0;
                float2 uv           : TEXCOORD2;
                float3 viewDirWS    : TEXCOORD3;
            };

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _Color;
                float4 _SpecularColor;
                float  _SpecularPower;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS.xyz);

                o.viewDirWS = GetWorldSpaceViewDir(o.positionWS);

                o.uv = v.texcoord.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;

                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                Light light = GetMainLight();
                half4 lightColor = half4(light.color * light.distanceAttenuation , 1.0);
                half3 worldLightDir = light.direction;

                half3 worldNormal = normalize(i.normalWS);

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap , sampler_BaseMap , i.uv);

                half3 diffuse = lightColor.rgb * baseMap.rgb * max(0 ,dot(worldNormal , worldLightDir));

                half3 viewDir = normalize(i.viewDirWS);
                half3 halfDir = normalize(worldLightDir + viewDir);

                half3 specular = lightColor.rgb * _SpecularColor.rgb * pow(max(0 , dot(worldNormal , halfDir)) , _SpecularPower);

                FinalColor =  half4(diffuse + specular , 1.0);

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
