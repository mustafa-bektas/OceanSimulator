Shader "Custom/WaterShader_FBM"
{
    Properties
    {
        _Amplitude ("Wave Amplitude", Range(0, 10)) = 0.5
        _Frequency ("Wave Frequency", Range(0, 20)) = 2.0
        _Speed ("Wave Speed", Range(0, 5)) = 1.0
        _MaxPeak ("Max Peak", Range(0.1, 10.0)) = 1.6
        _PeakOffset ("Peak Offset", Range(0.0, 8.0)) = 1.6
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
        _FresnelBias ("Fresnel Bias", Range(0, 1)) = 0.02
        _FresnelStrength ("Fresnel Strength", Range(0, 2)) = 1.0
        _FresnelShininess ("Fresnel Shininess", Range(1, 10)) = 5.0
        _TipColor ("Wave Tip Color", Color) = (1,1,1,1)
        _TipAttenuation ("Tip Attenuation", Range(0.1, 5.0)) = 2.0
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
                float3 worldPos : TEXCOORD0;
                float3 objectPos : TEXCOORD1;
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
            float _FresnelBias;
            float _FresnelStrength;
            float _FresnelShininess;
            float _TipColor;
            float _TipAttenuation;

            
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
                
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.objectPos = v.vertex.xyz; // Pass original position for normal calculation
                o.vertex = UnityObjectToClipPos(v.vertex);
                
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // Calculate normals in fragment shader
                float eps = 0.0001; // Sampling distance
                float3 pos = i.objectPos;
                
                // Sample height at neighboring points
                float hL = vertexFBM(pos + float3(-eps, 0, 0)).x;
                float hR = vertexFBM(pos + float3(eps, 0, 0)).x;
                float hD = vertexFBM(pos + float3(0, 0, -eps)).x;
                float hU = vertexFBM(pos + float3(0, 0, eps)).x;
                
                // Calculate gradient
                float3 objectNormal = normalize(float3(
                    (hL - hR) / (2.0 * eps) * _NormalStrength,
                    1.0,
                    (hD - hU) / (2.0 * eps) * _NormalStrength
                ));
                
                float3 normal = normalize(UnityObjectToWorldNormal(objectNormal));
                
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 halfwayDir = normalize(lightDir + viewDir);
                
                float NdotL = max(0, dot(normal, lightDir));
                
                // Schlick Fresnel
                float base = 1.0 - dot(viewDir, normal);
                float fresnel = pow(base, _FresnelShininess);
                fresnel = fresnel + _FresnelBias * (1.0 - fresnel);
                fresnel *= _FresnelStrength;
                
                // Basic water color with fresnel
                fixed3 waterColor = fixed3(0.0, 0.25, 0.65);
                fixed3 ambient = waterColor * 0.15;
                fixed3 diffuse = waterColor * NdotL * (1.0 - fresnel);
                
                // Specular with fresnel
                float NdotH = max(0, dot(normal, halfwayDir));
                float spec = pow(NdotH, _Shininess) * NdotL;
                fixed3 specular = _SpecularColor.rgb * spec * fresnel * _SpecularStrength;
                
                // Simple fresnel reflection (sky color)
                fixed3 fresnelColor = fixed3(0.7, 0.9, 1.0) * fresnel;
                
                fixed3 finalColor = ambient + diffuse + specular + fresnelColor;
                return fixed4(finalColor, 1.0);
            }
            ENDCG
        }
    }
}