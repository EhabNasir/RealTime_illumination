#include "Common.hlsl"

[shader("miss")] void Miss(inout HitInfo payload
                           : SV_RayPayload) {
    
    float3 rayDir = WorldRayOrigin();
    
    payload.colorAndDistance = float4((0.0f), 0.0f, 0.0f, 0);
    payload.colorAndDistance = float4((1.0f), 0.0f, 0.0f, 1);
}