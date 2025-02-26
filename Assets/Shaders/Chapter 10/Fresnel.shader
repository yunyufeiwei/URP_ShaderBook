Shader "URP/Chapter 10/Fresnel"
{
    Properties
    {
        _Color("Color" , Color) =(1,1,1,1)
        _FresnelScale("Fresnel Scale" , Range(0 ,1)) = 0.5
        _Cubemap("Cubemap" , Cube) = "_Skybox"{}
        // _power("Power" , Range(0.01,20)) = 5
        _power("Power" , float) = 5.0
        _MinFresnelValue("MinFresnelValue" , int) = 0.0
        _MaxFresnelValue("MaxFresnelValue" , int) = 1.0
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
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 positionWS   : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float3 viewDirWS    : TEXCOORD2;
                float3 worldRef1    : TEXCOORD3;
            };

            TEXTURECUBE(_Cubemap);SAMPLER(sampler_Cubemap);

            CBUFFER_START(UnityPerMaterial)
                half4 _Color;
                half  _FresnelScale;
                half  _power;
                half  _MinFresnelValue;
                half  _MaxFresnelValue;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS.xyz);
                o.viewDirWS = GetWorldSpaceViewDir(o.positionWS);

                o.worldRef1 = reflect(-o.viewDirWS , o.normalWS);

                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                Light light = GetMainLight();
                half3 lightColor = light.color * light.distanceAttenuation;
                half3 worldLightDir = light.direction;

                half3 worldNormal = normalize(i.normalWS);
                half3 worldViewDir = normalize(i.viewDirWS);

                half3 reflectionTex = SAMPLE_TEXTURECUBE(_Cubemap, sampler_Cubemap, i.worldRef1);

                //菲涅尔公式F(v,n) = F(0) + (1 - F(0)(1 - v.n)pow 5)
                half fresnel = _FresnelScale + (1 - _FresnelScale) * pow(1 - dot(worldNormal , worldViewDir) , _power);
                fresnel = 1 - smoothstep(_MinFresnelValue , _MaxFresnelValue , fresnel);

                half3 diffuse  = lightColor.rgb * _Color.rgb * max(0 , dot (worldNormal , worldLightDir));

                FinalColor = half4(lerp(diffuse , reflectionTex , saturate(fresnel)) , 1.0);

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
