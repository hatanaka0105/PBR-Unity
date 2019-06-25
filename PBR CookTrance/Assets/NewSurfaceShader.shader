// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/NewSurfaceShader" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_AlbedoTex("Albedo (RGB)", 2D) = "white" {}
		_NormalTex("Normal (RGB)", 2D) = "white" {}
		_MetalicTex("Metalic (RGB)", 2D) = "white" {}
		_RoughnessTex("Roughness (RGB)", 2D) = "white" {}
		_FresnelReflectance("Fresnel Reflectance", Float) = 0.5
	}
		SubShader{
			Pass {
				Tags { "LightMode" = "ForwardBase" }

				CGPROGRAM
				#include "Lighting.cginc"

				sampler2D _AlbedoTex;
				sampler2D _NormalTex;
				sampler2D _RoughnessTex;
				sampler2D _MetalicTex;
				uniform float4 _Color;
				uniform float _FresnelReflectance;

				struct appdata {
					float4 vertex : POSITION;
					float3 normal : NORMAL;
					float4 tangent : TANGENT;
					float2 texcoord : TEXCOORD0;
				};

				struct v2f {
					float4 pos : SV_POSITION;
					float3 normal : TEXCOORD1;
					float2 uv : TEXCOORD2;
					float3 lightDir : TEXCOORD3;
					float3 viewDir : TEXCOORD4;
				};

				#pragma vertex vert
				#pragma fragment frag

				// D（GGX）の項
				float D_GGX(float3 H, float3 N, float roughness) {
					float NdotH = saturate(dot(H, N));
					float alpha = roughness * roughness;
					float alpha2 = alpha * alpha;
					float t = ((NdotH * NdotH) * (alpha2 - 1.0) + 1.0);
					float PI = 3.1415926535897;
					return alpha2 / (PI * t * t);
				}

				// フレネルの項
				float Flesnel(float3 V, float3 H) {
					float VdotH = saturate(dot(V, H));
					float F0 = saturate(_FresnelReflectance);
					float F = pow(1.0 - VdotH, 5.0);
					F *= (1.0 - F0);
					F += F0;
					return F;
				}

				// G - 幾何減衰の項（クック トランスモデル）
				float G_CookTorrance(float3 L, float3 V, float3 H, float3 N) {
					float NdotH = saturate(dot(N, H));
					float NdotL = saturate(dot(N, L));
					float NdotV = saturate(dot(N, V));
					float VdotH = saturate(dot(V, H));

					float NH2 = 2.0 * NdotH;
					float g1 = (NH2 * NdotV) / VdotH;
					float g2 = (NH2 * NdotL) / VdotH;
					float G = min(1.0, min(g1, g2));
					return G;
				}


				v2f vert(appdata v) {
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);

					o.uv = v.texcoord.xy;

					TANGENT_SPACE_ROTATION;
					o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex));
					o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex));


					return o;
				}

				float4 frag(v2f i) : COLOR {
					float3 albedo = tex2D(_AlbedoTex, i.uv).rgb;
					// 環境光とマテリアルの色を合算
					float3 ambientLight = unity_AmbientEquator.xyz * albedo;

					//法線計算
					i.lightDir = normalize(i.lightDir);
					i.viewDir = normalize(i.viewDir);
					float3 halfDir = normalize(i.lightDir + i.viewDir);

					// ノーマルマップから法線情報を取得する
					float3 normal = UnpackNormal(tex2D(_NormalTex, i.uv));
					i.normal = normal;

					// ワールド空間上のライト位置と法線との内積を計算
					float NdotL = saturate(dot(i.normal, i.lightDir));

					// ワールド空間上の視点（カメラ）位置と法線との内積を計算
					float NdotV = saturate(dot(i.normal, i.viewDir));

					float3 roughnessTex = tex2D(_RoughnessTex, i.uv).xyz;
					float roughness = saturate((roughnessTex.x + roughnessTex.y + roughnessTex.z) / 3);

					// D_GGXの項
					float D = D_GGX(halfDir, i.normal, roughness);

					// Fの項
					float F = Flesnel(i.viewDir, halfDir);

					// Gの項
					float G = G_CookTorrance(i.lightDir, i.viewDir, halfDir, i.normal);

					// スペキュラおよびディフューズを計算
					float specularReflection = (D * F * G) / (4 * NdotV * NdotL + 0.000001);
					float3 diffuseReflection = _LightColor0.xyz * albedo.xyz * NdotL;

					float3 metalTex = tex2D(_MetalicTex, i.uv).xyz;
					float metalic = saturate((metalTex.r + metalTex.g + metalTex.b) / 3);

					// 最後に色を合算して出力
					float3 color = ambientLight + (diffuseReflection * (1 - metalic) + specularReflection * metalic);
					return float4(color, 1.0);
				}
				ENDCG
			 }
		}
		FallBack "Diffuse"
		
}