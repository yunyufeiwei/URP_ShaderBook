Shader "URP/Chapter 7/NormalMapTangentSpace"
{
    Properties
    {
        _DiffuseColor("DiffuseColor",Color) = (1,1,1,1)
        _BaseMap ("BaseMap", 2D) = "white" {}
        _BumpMap("BumpMap",2D) ="bump"{}
        _BumpScale("BumpScale",float) = 1
        _SpecularColor("SpecluarColor",Color) = (1,1,1,1)
        [PowerSlider(20)]_SpecularPower("SpecularPower",Range(1,50)) = 8
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
                float4 uv           : TEXCOORD0;
                float3 viewDirTS    : TEXCOORD2;
                float3 lightDirTS   : TEXCOORD3;
            };

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap);SAMPLER(sampler_BumpMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _DiffuseColor;
                float4 _BaseMap_ST;
                float4 _BumpMap_ST;
                float  _BumpScale;
                float4 _SpecularColor;
                float  _SpecularPower;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o=(Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);

                //使用xy分量来存储_BaseMap的纹理坐标
                o.uv.xy = v.texcoord * _BaseMap_ST.xy + _BaseMap_ST.zw;
                //使用zw分量来存储_BumpMap的纹理坐标
                o.uv.zw = v.texcoord * _BumpMap_ST.xy + _BumpMap_ST.zw;

                half signDir = real(v.tangentOS.w) * GetOddNegativeScale();
                float3 binormal = cross(normalize(v.normalOS),normalize(v.tangentOS.xyz)) * signDir;
                float3x3 TBN = float3x3(v.tangentOS.xyz , binormal , v.normalOS); 

                Light light = GetMainLight();
                half3 lightDirWS = light.direction;
                half3 viewDirWS = GetWorldSpaceViewDir(positionWS);

                //
                o.lightDirTS = mul(TBN , lightDirWS);   //切线空间下的光照方向
                o.viewDirTS = mul(TBN , viewDirWS);     //切线空间下的视角方向


                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                Light light = GetMainLight();
                half3 lightColor = half4(light.color * light.distanceAttenuation , 1.0);

                half3 tangentLightDir = normalize(i.lightDirTS);
                half3 tangentViewDir = normalize(i.viewDirTS);

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap , sampler_BaseMap , i.uv.xy);
                half4 normalMap = SAMPLE_TEXTURE2D(_BumpMap , sampler_BumpMap , i.uv.zw);
                half3 normalTS = UnpackNormalScale(normalMap , _BumpScale);

                half3 diffuse = lightColor * _DiffuseColor.rgb * baseMap.rgb * max(0.0 , dot(normalTS,tangentLightDir));
                half3 halfDir = normalize(tangentLightDir + tangentViewDir);
                half3 specular = lightColor * _SpecularColor.rgb * pow(max(0.0 , dot(normalTS,halfDir)),_SpecularPower);

                FinalColor = half4(diffuse + specular , 1.0);

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
