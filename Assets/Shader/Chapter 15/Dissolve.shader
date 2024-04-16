Shader "URP/Chapter 15/Dissolve"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpMap("Bump Map",2D) = "white"{}
        _BurnMap("Burn Map",2D) = "white"{}
        _BurnAmount("BurnAmount",Range(0,1)) = 0.0
        _LineWidth("BurnLineWidth",Range(0,1)) = 0.1
        [HDR]_BurnFirstColor("BurnFirstColor",Color) = (1,0,0,01)
        [HDR]_BurnSecondColor("BurnSecondColor",Color) = (1,0,0,1)
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
                float4 positionHCS      : SV_POSITION;
                float2 uvMainMap        : TEXCOORD0;
                float2 uvBumpMap        : TEXCOORD1;
                float2 uvBurnMap        : TEXCOORD2;
                float3 positionWS       : TEXCOORD3;
                float3 normalWS         : TEXCOORD4;
                float3 tangentWS        : TEXCOORD5;
                float3 bitangentWS      : TEXCOORD6;
                float3 viewWS           : TEXCOORD7;
            };

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_BumpMap); SAMPLER(sampler_BumpMap);
            TEXTURE2D(_BurnMap); SAMPLER(sampler_BurnMap);
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _BumpMap_ST;
                float4 _BurnMap_ST;
                float  _BurnAmount;
                float  _LineWidth;
                float4 _BurnFirstColor;
                float4 _BurnSecondColor;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o=(Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.normalWS = normalize(TransformObjectToWorldNormal(v.normalOS));
                o.tangentWS = TransformObjectToWorldDir(v.tangentOS.xyz);
                half sign = real(v.tangentOS.w) * GetOddNegativeScale();
                o.bitangentWS = cross(o.normalWS,o.tangentWS) * sign;

                o.viewWS = GetWorldSpaceViewDir(o.positionWS);

                o.uvMainMap = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uvBumpMap = TRANSFORM_TEX(v.texcoord,_BumpMap);
                o.uvBurnMap = TRANSFORM_TEX(v.texcoord,_BurnMap);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                Light light = GetMainLight();
                half3 worldLightDir = light.direction;
                half4 lightColor = half4(light.color * light.distanceAttenuation , 1.0);

                half3x3 TBN = float3x3(i.tangentWS,i.bitangentWS,i.normalWS);
                half4 normalMap = SAMPLE_TEXTURE2D(_BumpMap,sampler_BumpMap,i.uvBumpMap);
                half3 normalTS = UnpackNormal(normalMap);
                half3 worldNormalDir = normalize(TransformTangentToWorld(normalTS,TBN,true));

                half3 albedo = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uvMainMap);
                half3 diffuse = lightColor.rgb * albedo * max(0.0,dot(worldLightDir,worldNormalDir));

                half3 ambient = _GlossyEnvironmentColor.rgb * albedo;

                half burn = SAMPLE_TEXTURE2D(_BurnMap,sampler_BurnMap,i.uvBurnMap).r;

                half t = 1 - smoothstep(0.0,_LineWidth , burn.r - _BurnAmount);
                half3 burnColor = lerp(_BurnFirstColor,_BurnSecondColor,t).rgb;
                burnColor = pow(burnColor,5);

                clip(burn - _BurnAmount);

                FinalColor = half4(lerp(ambient + diffuse , burnColor, t * step(0.001,_BurnAmount)),1.0);
                
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
