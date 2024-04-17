Shader "URP/ShaderBook/Chapter 15/Water"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _WaveMap("WaveMap",2D) = "white"{}      //使用法线来流动
        _WaveSacle("WaveScale",float) = 1
        _WaveXSpeed("WaveXSpeed",Range(-0.1,0.1)) = 0.01
        _WaveYSpeed("WaveYSpeed",Range(-0.1,0.1)) = 0.01
        _CubeMap("CubeMap",Cube) = "_Skybox"{}
        _Distortion("Distortion",Range(0,500)) = 0  //折射
        _FresnelPow("FresnelPow",Range(0,8)) = 1
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent"}
        LOD 100
        
        //GrabPass { "_RefractionTex" }  //通过关键字GrabPass定义了一个抓取屏幕图像的Pass，在这个pass中我们定义了一个字符串，该字符串内的名称决定了抓取得到的屏幕图像将会背存入哪个纹理

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
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
                float4 uv               : TEXCOORD0;
                float4 scrPos           : TEXCOORD1;
                float4 TtoW0            : TEXCOORD2;
                float4 TtoW1            : TEXCOORD3;
                float4 TtoW2            : TEXCOORD4;
            };
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_WaveMap); SAMPLER(sampler_WaveMap);
            TEXTURECUBE(_CubeMap);SAMPLER(sampler_CubeMap);
            TEXTURE2D(_CameraOpaqueTexture);SAMPLER(sampler_CameraOpaqueTexture);
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _MainTex_ST;
                float4 _WaveMap_ST;
                float  _WaveSacle;
                float  _WaveXSpeed;
                float  _WaveYSpeed;
                float  _Distortion;
                float  _FresnelPow;
                float4 _CameraOpaqueTexture_TexelSize;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;

                //通过内置的方法，将模型本地位置数据传入，输出模型顶点的世界空间、视图空间、裁剪空间以及NDC空间位置
                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionHCS = positionInputs.positionCS;
                //通过传入模型空间下的法线和切线数据，使用内置方法计算输出世界空间下的法线、切线、付切线向量
                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS,v.tangentOS);
                //在进行必要的顶点坐标变换后，通过调用ComputeGrabScreenPos来得到对应被抓取屏幕图像的采样坐标
                o.scrPos = positionInputs.positionNDC;

                //构建TBN
                o.TtoW0 = float4(normalInput.tangentWS.x , normalInput.bitangentWS.x , normalInput.normalWS.x,positionInputs.positionWS.x);
                o.TtoW1 = float4(normalInput.tangentWS.y , normalInput.bitangentWS.y , normalInput.normalWS.y,positionInputs.positionWS.y);
                o.TtoW2 = float4(normalInput.tangentWS.z , normalInput.bitangentWS.z , normalInput.normalWS.z,positionInputs.positionWS.z);
                
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _WaveMap);
                
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;
                half3 positionWS = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
                half3 viewDir = GetWorldSpaceViewDir(positionWS);
                half2 speed = _Time.y * float2(_WaveXSpeed,_WaveYSpeed);        //后边的uv流动速度

                //采样法线（法线贴图是切线空间）
                half3 bump1 = UnpackNormalScale(SAMPLE_TEXTURE2D(_WaveMap,sampler_WaveMap,i.uv.zw + speed),_WaveSacle).rgb;
                half3 bump2 = UnpackNormalScale(SAMPLE_TEXTURE2D(_WaveMap,sampler_WaveMap,i.uv.zw - speed) , _WaveSacle).rgb;
                half3 bump = normalize(bump1 + bump2);

                //切线空间下的位移
                float2 offset = bump.xy * _Distortion * _CameraOpaqueTexture_TexelSize.xy;
                i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;
                half3 refractColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture,sampler_CameraOpaqueTexture,i.scrPos.xy/i.scrPos.w).rgb;
                
                //转换切线空间的法线到世界空间
                bump = normalize(half3(dot(i.TtoW0.xyz,bump) , dot(i.TtoW1.xyz,bump),dot(i.TtoW2,bump)));

                half3 baseMap = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.xy).rgb;
                half3 refDir = reflect(-viewDir,bump);
                half3 refColor = SAMPLE_TEXTURECUBE(_CubeMap,sampler_CubeMap,refDir).rgb * baseMap.rgb * _Color.rgb;

                half fresnel = pow(1 - saturate(dot(viewDir,bump)),_FresnelPow);

                FinalColor = half4(refColor * fresnel + refractColor * (1 - fresnel) , 1.0);
                
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
