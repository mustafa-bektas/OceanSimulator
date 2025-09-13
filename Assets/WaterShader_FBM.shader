Shader "Custom/WaterShader_FBM"
{
    Properties
    {
        _Amplitude ("Wave Amplitude", Range(0, 2)) = 0.5
        _Frequency ("Wave Frequency", Range(0, 10)) = 2.0
        _Speed ("Wave Speed", Range(0, 5)) = 1.0
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _Shininess ("Shininess", Range(1, 100)) = 32
        _SpecularStrength ("Specular Strength", Range(0, 2)) = 1.0
        _WindDirection ("Wind Direction", Vector) = (1, 0, 0.3, 0)
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
            fixed4 _SpecularColor;
            float _Shininess;
            float _SpecularStrength;
            float4 _WindDirection;
            
            float waveFunction(float x)
            {
                return exp(sin(x) - 1.0);
            }
            
            float waveDerivative(float x)
            {
                return exp(sin(x) - 1.0) * cos(x);
            }

            float3 calculateWaveNormal(float3 pos)
            {
                float time = _Time.y;
                float2 windDir = normalize(_WindDirection.xy);
                
                float2 dir1 = windDir;
                float2 dir2 = float2(windDir.x * 0.707 - windDir.y * 0.707, windDir.x * 0.707 + windDir.y * 0.707);
                float2 dir3 = float2(-windDir.y, windDir.x); // 90° rotation (cross waves)
                float2 dir4 = float2(windDir.x * 0.707 + windDir.y * 0.707, -windDir.x * 0.707 + windDir.y * 0.707);

                float phase1 = dot(pos.xz, dir1) * _Frequency * 1.0 + time * _Speed * 0.8;
                float phase2 = dot(pos.xz, dir2) * _Frequency * 0.6 + time * _Speed * 1.2;
                float phase3 = dot(pos.xz, dir3) * _Frequency * 0.4 + time * _Speed * 0.6;
                float phase4 = dot(pos.xz, dir4) * _Frequency * 0.8 + time * _Speed * 1.5;

                float dFdx = 
                    waveDerivative(phase1) * dir1.x * _Frequency * 1.0 * _Amplitude * 1.0 +
                    waveDerivative(phase2) * dir2.x * _Frequency * 0.6 * _Amplitude * 0.7 +
                    waveDerivative(phase3) * dir3.x * _Frequency * 0.4 * _Amplitude * 0.4 +
                    waveDerivative(phase4) * dir4.x * _Frequency * 0.8 * _Amplitude * 0.5;
                
                float dFdz = 
                    waveDerivative(phase1) * dir1.y * _Frequency * 1.0 * _Amplitude * 1.0 +
                    waveDerivative(phase2) * dir2.y * _Frequency * 0.6 * _Amplitude * 0.7 +
                    waveDerivative(phase3) * dir3.y * _Frequency * 0.4 * _Amplitude * 0.4 +
                    waveDerivative(phase4) * dir4.y * _Frequency * 0.8 * _Amplitude * 0.5;
                
                float3 normal = normalize(float3(-dFdx, 1.0, -dFdz));
                return normal;
            }

            v2f vert (appdata v)
            {
                v2f o;
                
                float time = _Time.y;
                float2 windDir = normalize(_WindDirection.xy);
                
                float2 dir1 = windDir;
                float2 dir2 = float2(windDir.x * 0.707 - windDir.y * 0.707, windDir.x * 0.707 + windDir.y * 0.707); 
                float2 dir3 = float2(-windDir.y, windDir.x);
                float2 dir4 = float2(windDir.x * 0.707 + windDir.y * 0.707, -windDir.x * 0.707 + windDir.y * 0.707);

                // Calculate waves with proper directional vectors
                float wave0 = waveFunction(dot(v.vertex.xz, dir1) * _Frequency * 1.0 + time * _Speed * 0.8) * _Amplitude * 1.0;
                float wave1 = waveFunction(dot(v.vertex.xz, dir2) * _Frequency * 0.6 + time * _Speed * 1.2) * _Amplitude * 0.7;
                float wave2 = waveFunction(dot(v.vertex.xz, dir3) * _Frequency * 0.4 + time * _Speed * 0.6) * _Amplitude * 0.4;
                float wave3 = waveFunction(dot(v.vertex.xz, dir4) * _Frequency * 0.8 + time * _Speed * 1.5) * _Amplitude * 0.5;
                
                float wavesum = wave0 + wave1 + wave2 + wave3;
                v.vertex.y += wavesum;
                
                float3 objectNormal = calculateWaveNormal(v.vertex.xyz);
                o.normal = normalize(mul((float3x3)unity_ObjectToWorld, objectNormal));
                
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal = i.normal;
                
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 halfwayDir = normalize(lightDir + viewDir);
                float NdotL = max(0, dot(normal, lightDir));
                float NdotH = max(0, dot(normal, halfwayDir));
                float specular = pow(NdotH, _Shininess) * _SpecularStrength;
                
                fixed3 waterColor = fixed3(0.1, 0.4, 1.0);
                fixed3 ambient = waterColor * 0.2;
                fixed3 diffuse = waterColor * NdotL;
                fixed3 specularReflection = _SpecularColor.rgb * specular;
                
                fixed3 finalColor = ambient + diffuse + specularReflection;
                
                return fixed4(finalColor, 1.0);
            }
            ENDCG
        }
    }
}