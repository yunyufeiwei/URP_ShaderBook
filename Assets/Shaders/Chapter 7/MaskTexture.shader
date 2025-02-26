Shader "URP/Chapter 7/MaskTexture"
{
    Properties
    {
        _DiffuseColor("DiffuseColor",Color) = (1,1,1,1)
        _BaseMap ("BaseMap", 2D) = "white" {}
        _BumpMap("BumpMap",2D) = "bump"{}
        _BumpScale("BumpScale",float) = 1

        _SpecularMask("SpecularMask",2D) = "white"{}
        _SpecularColor("SpecluarColor",Color) = (1,1,1,1)
        [PowerSlider(20)]_SpecularPower("SpecularPower",Range(1,255)) = 8
        _SpecularScale("SpecularScale",float) = 1
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
                float4 tangentOS    : TANGENT;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 positionWS   : TEXCOORD1;
                float3 viewDirWS    : TEXCOORD2;
                float3 normalWS     : TEXCOORD3;
                float3 tangentWS    : TEXCOORD4;
                float3 bitangentWS  : TEXCOORD5;
            };

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap);SAMPLER(sampler_BumpMap);
            TEXTURE2D(_SpecularMask);SAMPLER(sampler_SpecularMask);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _DiffuseColor;
                float4 _BumpMap_ST;
                float  _BumpScale;
                float4 _SpecularMask_ST;
                float4 _SpecularColor;
                float  _SpecularPower;
                float  _SpecularScale;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);

                //世界空间下的法线相关数据信息
                o.normalWS = normalize(TransformObjectToWorldNormal(v.normalOS));
                o.tangentWS = TransformObjectToWorldDir(v.tangentOS.xyz);
                half signDir = real(v.tangentOS.w) * GetOddNegativeScale();
                o.bitangentWS = cross(o.normalWS,o.tangentWS) * signDir;

                o.viewDirWS = GetWorldSpaceViewDir(o.positionWS);

                o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                Light light = GetMainLight();
                half4 lightColor = half4(light.color * light.distanceAttenuation , 1.0);
                half3 worldLightDir = light.direction;

                half3 worldViewDir = normalize(i.viewDirWS);
                half3 halfDir = normalize(worldLightDir + worldViewDir);

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap , sampler_BaseMap , i.uv);

                half4 normalMap = SAMPLE_TEXTURE2D(_BumpMap , sampler_BumpMap , i.uv);
                half3 normalTS = UnpackNormalScale(normalMap,_BumpScale);
                half3 worldNormal = normalize(TransformTangentToWorld(normalTS,float3x3(i.tangentWS.xyz , i.bitangentWS.xyz , i.normalWS.xyz) , true));

                half4 specluarMask = SAMPLE_TEXTURE2D(_SpecularMask,sampler_SpecularMask,i.uv);

                half4 diffuse = lightColor * _DiffuseColor * baseMap * max(0.0 , dot(worldNormal,worldLightDir) * 0.5 + 0.5);
                half4 specular = lightColor * _SpecularColor * pow(max(0.0 , dot(worldNormal,halfDir)),_SpecularPower) * specluarMask.r * _SpecularScale;

                FinalColor = diffuse + specular;

                return FinalColor;
            }
            ENDHLSL
        }
    }
}

