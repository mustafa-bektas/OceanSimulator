Shader "Custom/WaterShader_SumOfSines"
{
    Properties
    {
        _Amplitude ("Wave Amplitude", Range(0, 2)) = 0.5
        _Frequency ("Wave Frequency", Range(0, 10)) = 2.0
        _Speed ("Wave Speed", Range(0, 5)) = 1.0
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _Shininess ("Shininess", Range(1, 100)) = 32
        _SpecularStrength ("Specular Strength", Range(0, 2)) = 1.0
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
            
            float3 calculateWaveNormal(float3 pos)
            {
                float time = _Time.y;

                float dFdx = 
                    cos(pos.x * _Frequency * 0.15 + pos.z * _Frequency * 0.1 + time * _Speed * 0.3) * _Frequency * 0.15 * _Amplitude * 1 +
                    cos(pos.x * _Frequency * 0.4 + pos.z * _Frequency * 0.25 + time * _Speed * 0.7) * _Frequency * 0.4 * _Amplitude * 0.6 +
                    cos(pos.x * _Frequency * 0.8 + pos.z * _Frequency * 1.2 + time * _Speed * 1.8) * _Frequency * 0.8 * _Amplitude * 0.3 +
                    cos(pos.x * _Frequency * 1.5 - pos.z * _Frequency * 0.8 + time * _Speed * 2.2) * _Frequency * 1.5 * _Amplitude * 0.15;
                
                float dFdz = 
                    cos(pos.x * _Frequency * 0.15 + pos.z * _Frequency * 0.1 + time * _Speed * 0.3) * _Frequency * 0.1 * _Amplitude * 1.2 +
                    cos(pos.x * _Frequency * 0.4 + pos.z * _Frequency * 0.25 + time * _Speed * 0.7) * _Frequency * 0.25 * _Amplitude * 0.6 +
                    cos(pos.x * _Frequency * 0.8 + pos.z * _Frequency * 1.2 + time * _Speed * 1.8) * _Frequency * 1.2 * _Amplitude * 0.3 +
                    cos(pos.x * _Frequency * 1.5 - pos.z * _Frequency * 0.8 + time * _Speed * 2.2) * (-_Frequency * 0.8) * _Amplitude * 0.15; // Note the negative here
                
                float3 normal = normalize(float3(-dFdx, 1.0, -dFdz));
                return normal;
            }

            v2f vert (appdata v)
            {
                v2f o;
                
                float time = _Time.y;

                float wave0 = sin(v.vertex.x * _Frequency * 0.15 + v.vertex.z * _Frequency * 0.1 + time * _Speed * 0.3) * _Amplitude * 1;
                float wave1 = sin(v.vertex.x * _Frequency * 0.4 + v.vertex.z * _Frequency * 0.25 + time * _Speed * 0.7) * _Amplitude * 0.6;
                float wave2 = sin(v.vertex.x * _Frequency * 0.8 + v.vertex.z * _Frequency * 1.2 + time * _Speed * 1.8) * _Amplitude * 0.3;
                float wave3 = sin(v.vertex.x * _Frequency * 1.5 - v.vertex.z * _Frequency * 0.8 + time * _Speed * 2.2) * _Amplitude * 0.15;
                
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