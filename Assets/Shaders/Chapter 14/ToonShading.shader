Shader "URP/Chapter 14/ToonShading"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _RampTex("RampTex",2D) = "white"{}
        _SpecularColor("SpecularColor" , Color) = (1,1,1,1)
        _SpecularScale("SpecularScale" , Range(0,1)) = 0.01
        
        _OutlineColor("OutlineColor",Color) = (1,1,1,1)
        _OutlineWidth("OutlineWidth",Range(0,1)) = 0
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry"}
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
                float4 tangent      : TANGENT;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float3 positionWS   : TEXCOORD2;
                float3 viewDirWS    : TEXCOORD3;
            };
            
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_RampTex);SAMPLER(sampler_RampTex);
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _MainTex_ST;
                float4 _SpecularColor;
                float  _SpecularScale;
                
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = normalize(TransformObjectToWorldNormal(v.normalOS));
                o.viewDirWS = GetWorldSpaceViewDir(o.positionWS);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

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
                half3 worldHalfDir = normalize(worldLightDir + worldViewDir);

                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , i.uv);
                half3 albedo = mainTex.rgb * _Color.rgb;

                half halfLambert = dot(worldLightDir , worldNormal) * 0.5 + 0.5;
                half2 rampUV = half2(halfLambert,halfLambert);
                half4 rampTex = SAMPLE_TEXTURE2D(_RampTex , sampler_RampTex , rampUV);

                half3 diffuse = lightColor.rgb * albedo * rampTex.rgb;

                half blinnPhong = dot(worldNormal , worldHalfDir);
                half width = fwidth(blinnPhong) * 2.0;
                half3 specular = lightColor.rgb * _SpecularColor.rgb * lerp(0 , 1 , smoothstep(-width , width , _SpecularScale - 1)) * step(0.0001,_SpecularScale);

                FinalColor = half4(diffuse + specular, 1.0);
                return FinalColor;
            }
            ENDHLSL
        }

        pass
        {
            NAME "Outline"
            Tags{"LightMode" = "Outline"}
            Cull Front

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _OutlineColor;
                float  _OutlineWidth;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;

                half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                half3 positionVS = TransformWorldToView(positionWS);

                positionVS.z += _OutlineWidth;
                o.positionHCS = TransformWViewToHClip(positionVS);

                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                return half4(_OutlineColor.rgb , 1.0);
            }
            ENDHLSL
        }
    }
}
