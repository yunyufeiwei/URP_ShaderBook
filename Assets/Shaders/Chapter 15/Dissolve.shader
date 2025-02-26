Shader "URP/Chapter 15/Dissolve"
{
    Properties
    {
        [HideInInspector]_BurnAmount("Burn Amount" , Range(0 , 1)) = 0.0  //定义消融程度
        _LineWidth("Burn Line Width" , Range(0 , 1)) = 0.1  //定义消融边缘的宽度，值越大，边缘的蔓延范围越广
        _MainTex("MainTexture" , 2D) = "white"{}
        _BumpMap("Bump Map" , 2D) = "white"{}
        _BurnFirstColor("Burn First Color" , Color) = (1 , 0 , 0 , 1)
        _BurnSecondColor("Burn Second Color" , Color) = (1 , 0 , 0 , 1)
        _BurnMap("Burn Map" , 2D) = "whtie"{}
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry"}

        pass
        {
            Tags{"LightMode" = "UniversalForward"}
            Cull off 

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uvMainTex    : TEXCOORD0;
                float2 uvBumpMap    : TEXCOORD1;
                float2 uvBurnMap    : TEXCOORD2;
                float3 lightDir     : TEXCOORD3;
                float3 positionWS   : TEXCOORD4;
                float3 normalWS     : TEXCOORD5;
                float3 tangentWS    : TEXCOORD6;
                float3 bitangentWS  : TEXCOORD7;
                float3 viewWS       : TEXCOORD8;
            };

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_BumpMap);SAMPLER(sampler_BumpMap);
            TEXTURE2D(_BurnMap);SAMPLER(sampler_BurnMap);

            CBUFFER_START(UnityPerMaterial)
                float _BurnAmount;
                float _LineWidth;
                float4 _MainTex_ST;
                float4 _BumpMap_ST;
                float4 _BurnFirstColor;
                float4 _BurnSecondColor;
                float4 _BurnMap_ST;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);

                o.normalWS = normalize(TransformObjectToWorldNormal(v.normalOS));
                o.tangentWS = TransformObjectToWorldDir(v.tangentOS.xyz);
                half signDir = real(v.tangentOS.w) * GetOddNegativeScale();
                o.bitangentWS =cross(o.normalWS , o.tangentWS) * signDir;   

                o.viewWS = GetWorldSpaceViewDir(o.positionWS); 

                o.uvMainTex = TRANSFORM_TEX(v.texcoord , _MainTex);
                o.uvBumpMap = TRANSFORM_TEX(v.texcoord , _BumpMap);
				o.uvBurnMap = TRANSFORM_TEX(v.texcoord , _BurnMap);

                return o;

            }

            half4 frag(Varyings i): SV_TARGET
            {
                //光照相关数据
                Light light  = GetMainLight();
                half3 lightColor = light.color * light.distanceAttenuation;
                half3 lightDir   = light.direction;
                
                //对噪声纹理进行采样
                half  burn = SAMPLE_TEXTURE2D(_BurnMap , sampler_BurnMap , i.uvBurnMap).r;

                clip(burn - _BurnAmount);

                half3x3 TBN = float3x3(i.tangentWS.xyz , i.bitangentWS.xyz , i.normalWS.xyz);
                half3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap , sampler_BumpMap , i.uvBumpMap));
                half3 worldNormalDir = normalize(TransformTangentToWorld(normalTS , TBN , true));

                half3 albedo = SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , i.uvMainTex).rgb;

                half3 ambient = _GlossyEnvironmentColor.rgb * albedo;

                half3 diffuse = lightColor * albedo * max(0, dot(worldNormalDir, lightDir));

                half t = 1 - smoothstep(0.0, _LineWidth, burn.r - _BurnAmount);
				half3 burnColor = lerp(_BurnFirstColor, _BurnSecondColor, t).rgb;
				burnColor = pow(burnColor, 5);
				
				half3 finalColor = lerp(ambient + diffuse, burnColor, t * step(0.0001, _BurnAmount));
				
				return half4(finalColor, 1);

            }
            ENDHLSL

        }
    }
}
