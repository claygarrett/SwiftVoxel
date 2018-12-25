//
//  MatrixUtilities.swift
//  SwiftVoxel
//
//  Created by Clay Garrett on 12/22/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

import UIKit
import simd

class MatrixUtilities: NSObject {
    
    struct Quaternion {
        var w:Float;
        var x:Float;
        var y:Float;
        var z:Float;
    }
    
    static func normalizeQuaternion( q:Quaternion) -> Quaternion{
        
        let l:Float = sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w);
        let x = q.x / l;
        let y = q.y / l;
        let z = q.z / l;
        let w = q.w / l;
        return Quaternion(w: w, x: x, y: y, z: z);
    }
    
    
    // Function to find
    // cross product of two vector array.
    static func crossProduct3( a:simd_float3,  b:simd_float3)->simd_float3
    {
        let x = a.y * b.z - a.z * b.y;
        let y = a.x * b.z - a.z * b.x;
        let z = a.x * b.y - a.y * b.x;
        return [ x, y, z ];
    }
    
    
    static func matrixFloat4x4UniformScale(_ scale: Float)->matrix_float4x4 {
        let X:vector_float4 = [ scale, 0, 0, 0 ];
        let Y:vector_float4 = [ 0, scale, 0, 0 ];
        let Z:vector_float4 = [ 0, 0, scale, 0 ];
        let W:vector_float4 = [ 0, 0, 0, 1 ];
        
        return matrix_float4x4(X, Y, Z, W);
    }
    
    static func matrixFloat4x4Translation(t:vector_float3)->matrix_float4x4 {
        let X:vector_float4 = [ 1, 0, 0, 0 ]
        let Y:vector_float4 = [ 0, 1, 0, 0 ]
        let Z:vector_float4 = [ 0, 0, 1, 0 ]
        let W:vector_float4 = [ t.x, t.y, t.z, 1 ]
        let mat:matrix_float4x4 = matrix_float4x4(X, Y, Z, W)
        return mat
    };
    
    static func matrixFloat4x4Perspective(aspect: Float, fovy: Float, near:Float, far:Float)->matrix_float4x4
    {
        let yScale:Float = 1 / tan(fovy * 0.5);
        let xScale:Float = yScale / aspect;
        let zRange:Float = far - near;
        let zScale:Float = -(far + near) / zRange;
        let wzScale:Float = -2 * far * near / zRange;
        
        let P:vector_float4 = [ xScale, 0, 0, 0 ];
        let Q:vector_float4 = [ 0, yScale, 0, 0 ];
        let R:vector_float4 = [ 0, 0, zScale, -1 ];
        let S:vector_float4 = [ 0, 0, wzScale, 0 ];
        
        let mat:matrix_float4x4 = matrix_float4x4(P, Q, R, S);
        return mat;
    };
    
    static func dotProduct3(x:simd_float3, y: simd_float3)->Float {
        var out:Float=0;
        
        for i in 0..<3 {
            out += x[i] * y[i];
        }
        
        return out
    }
    
    static func magnitude3(x:simd_float3)->Float {
        return sqrt(pow(x.x, 2) + pow(x.y, 2) + pow(x.z, 2))
    }
    
    static func getMatrixFromQuat( q:Quaternion)->matrix_float4x4 {
        let sqw:Float = q.w*q.w;
        let sqx:Float = q.x*q.x;
        let sqy:Float = q.y*q.y;
        let sqz:Float = q.z*q.z;
        
        // invs (inverse square length) is only required if quaternion is not already normalised
        let invs:Float = 1 / (sqx + sqy + sqz + sqw);
        let m00:Float = ( sqx - sqy - sqz + sqw)*invs ; // since sqw + sqx + sqy + sqz =1/invs*invs
        let m11:Float = (-sqx + sqy - sqz + sqw)*invs ;
        let m22:Float = (-sqx - sqy + sqz + sqw)*invs ;
        
        var tmp1:Float = q.x*q.y;
        var tmp2:Float = q.z*q.w;
        let m10:Float = 2.0 * (tmp1 + tmp2)*invs ;
        let m01:Float = 2.0 * (tmp1 - tmp2)*invs ;
        
        tmp1 = q.x*q.z;
        tmp2 = q.y*q.w;
        let m20:Float = 2.0 * (tmp1 - tmp2)*invs ;
        let m02:Float = 2.0 * (tmp1 + tmp2)*invs ;
        tmp1 = q.y*q.z;
        tmp2 = q.x*q.w;
        let m21:Float = 2.0 * (tmp1 + tmp2)*invs ;
        let m12:Float = 2.0 * (tmp1 - tmp2)*invs ;
        
        let X:vector_float4 = [m00, m10, m20, 0]
        
        
        let Y:vector_float4 = [m01, m11, m21, 0]
        
        let Z:vector_float4 = [m02, m12, m22, 0];
        
        let W:vector_float4 = [0, 0, 0, 1]
        
        let mat = matrix_float4x4(X, Y, Z, W)
        return mat;
    }
    
    //MARK: - Rotations
    static func getRotation(from: vector_float3, to: vector_float3)->matrix_float4x4 {
        let dot = dotProduct3(x: from, y: to);
        let magA = magnitude3(x: from);
        let magB = magnitude3(x: to);
        let a = crossProduct3(a: from, b: to);
        let x = a.x;
        let y = a.y;
        let z = a.z;
        let w = sqrt((magA * magA) * (magB * magB)) + dot;
        var q = Quaternion(w: w, x: x, y: y, z: z)
        q = normalizeQuaternion(q: q);
        return getMatrixFromQuat(q: q);
    }
    
    //MARK: - Quaterinons
    
    static func getQuaternionFromAngles(xx: Float, yy: Float, zz: Float, a: Float) -> Quaternion {
        let factor = sin(a/2)
        let x = xx * factor;
        let y = yy * factor;
        let z = zz * factor;
        let w = cos(a/2.0)
        return Quaternion(w: w, x: x, y: y, z: z)
    }
}
