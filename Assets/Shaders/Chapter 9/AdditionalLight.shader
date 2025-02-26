Shader "URP/Chapter 9/AdditionalLight"
{
    Properties
    {
        _Color("Color" , Color) = (1,1,1,1)
        _SpecularColor("SpecularColor" , Color) = (1,1,1,1)
        [PowerSlider(20)]_SpecularPower("SpecularPower" , Range(8 , 256)) =20
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry"}

        Pass
        {
		    //URP下的额外光源计算与光照模型已经与Built-In完全不同，因此额外光源不在使用两个pass来实现
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
                
            };

            CBUFFER_START(UnityPerMaterial)
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
                half3 halfDir = normalize(worldLightDir + worldViewDir);

                half3 diffuse = lightColor.rgb * _Color.rgb * max(0 ,dot(worldNormal , worldLightDir));
                half3 specular = lightColor.rgb * _SpecularColor.rgb * pow(max(0 , dot(worldNormal , halfDir)) , _SpecularPower);

                int additionalLightCount = GetAdditionalLightsCount();  //获取额外光源数量
                for(int j = 0 ; j < additionalLightCount; j ++)
                {
                    light = GetAdditionalLight(j,i.positionWS);        //根据Index获取额外的光源数据
                    half3 attenuatedLightColor = light.color * light.distanceAttenuation;
                    diffuse  += LightingLambert(attenuatedLightColor , light.direction , worldNormal);
                    specular += LightingSpecular(attenuatedLightColor , light.direction , worldNormal , worldViewDir , _SpecularColor , _SpecularPower);
                }

                FinalColor = half4(diffuse + specular , 1.0);

                return FinalColor;
            }
            ENDHLSL
        }

    }
}