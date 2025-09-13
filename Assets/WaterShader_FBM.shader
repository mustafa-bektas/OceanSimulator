Shader "Custom/WaterShader_FBM"
{
    Properties
    {
        _Amplitude ("Wave Amplitude", Range(0, 3)) = 0.5
        _Frequency ("Wave Frequency", Range(0, 20)) = 2.0
        _Speed ("Wave Speed", Range(0, 5)) = 1.0
        _MaxPeak ("Max Peak", Range(0.1, 3.0)) = 1.6
        _PeakOffset ("Peak Offset", Range(0.0, 2.0)) = 1.6
        _Drag ("Wave Drag", Range(0.0, 1.0)) = 0.23
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _Shininess ("Shininess", Range(1, 100)) = 32
        _SpecularStrength ("Specular Strength", Range(0, 2)) = 1.0
        _Octaves ("FBM Octaves", Range(1, 60)) = 4
        _Lacunarity ("Lacunarity", Range(1.0, 3.0)) = 2.0
        _Persistence ("Persistence", Range(0.3, 1.0)) = 0.5
        _SpeedRamp ("Speed Ramp", Range(0.0, 2.0)) = 1.2
        _SeedIter ("Seed Iteration", Range(0.1, 2.0)) = 1.18
        _NormalStrength ("Normal Strength", Range(0.0,5.0)) = 1
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float3 worldPos : TEXCOORD0;
            };

            float _Amplitude;
            float _Frequency;
            float _Speed;
            float _MaxPeak;
            float _PeakOffset;
            float _Drag;
            fixed4 _SpecularColor;
            float _Shininess;
            float _SpecularStrength;
            int _Octaves;
            float _Lacunarity;
            float _Persistence;
            float _SpeedRamp;
            float _SeedIter;
            float _NormalStrength;
            
            float2 getDirectionForSeed(float seed)
            {
                return normalize(float2(cos(seed), sin(seed)));
            }

            float3 vertexFBM(float3 v)
            {
                float f = _Frequency;
                float a = _Amplitude;
                float speed = _Speed;
                float seed = 1.0; // Starting seed
                float3 p = v;
                float amplitudeSum = 0.0;

                float h = 0.0;
                float2 n = float2(0.0, 0.0);
                
                for (int wi = 0; wi < _Octaves; ++wi) {
                    float2 d = getDirectionForSeed(seed);

                    float x = dot(d, p.xz) * f + _Time.y * speed;
                    float wave = a * exp(_MaxPeak * sin(x) - _PeakOffset);
                    float dx = _MaxPeak * wave * cos(x);
                    
                    h += wave;
                    
                    n.x += dx * d.x * f;
                    n.y += dx * d.y * f;
                    
                    float dragScale = a / (_Amplitude + 0.001); 
                    dragScale *= 1.0 / (f / _Frequency); 
                    
                    p.xz += d * -dx * dragScale * _Drag * 0.1;

                    amplitudeSum += a;
                    f *= _Lacunarity;
                    a *= _Persistence;
                    speed *= _SpeedRamp;
                    seed += _SeedIter;
                }

                float3 output = float3(h, n.x, n.y);
                if (amplitudeSum > 0.0) {
                    output /= amplitudeSum;
                }
                
                return output;
            }

            v2f vert (appdata v)
            {
                v2f o;
                
                float3 fbmResult = vertexFBM(v.vertex.xyz);
                v.vertex.y += fbmResult.x;
                
                float3 objectNormal = normalize(float3(-fbmResult.y * _NormalStrength, 1.0, -fbmResult.z * _NormalStrength));
                o.normal = UnityObjectToWorldNormal(objectNormal);
                
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.vertex = UnityObjectToClipPos(v.vertex);
                
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal = normalize(i.normal);
                
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 halfwayDir = normalize(lightDir + viewDir);
                float NdotL = max(0, dot(normal, lightDir));
                float NdotH = max(0, dot(normal, halfwayDir));
                float specular = pow(NdotH, _Shininess) * _SpecularStrength;
                
                fixed3 waterColor = fixed3(0.0, 0.4, 1.0);
                fixed3 ambient = waterColor * 0.15;
                fixed3 diffuse = waterColor * NdotL;
                fixed3 specularReflection = _SpecularColor.rgb * specular;
                
                fixed3 finalColor = ambient + diffuse + specularReflection;
                
                return fixed4(finalColor, 1.0);
            }
            ENDCG
        }
    }
}