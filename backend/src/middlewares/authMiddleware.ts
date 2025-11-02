import { Request, Response, NextFunction } from 'express'; 
import jwt from 'jsonwebtoken'; 

const JWT_SECRET = process.env.JWT_SECRET || '1234'; 

// ✅ ตรวจสอบว่ามี JWT และเป็น admin หรือไม่ 
export const verifyAdmin = (req: Request, res: Response, next: NextFunction) => { 
  const authHeader = req.headers.authorization; 

  if (!authHeader || !authHeader.startsWith('Bearer ')) { 
    return res.status(401).json({ status: false, message: 
      'Unauthorized: Missing token' }); 
    } 
    
    const token = authHeader.split(' ')[1];
    try { 
      const decoded = jwt.verify(token, JWT_SECRET) as { 
        user_id: number; role: string }; 

// ✅ ตรวจสอบ role 
  if (decoded.role !== 'admin') {
    return res.status(403).json({ status: false, message: 
    'Forbidden: Admins only' }); 
    } 
// ✅ เก็บข้อมูลผู้ใช้ไว้ใน req เพื่อใช้ต่อ 
  (req as any).user = decoded; 
  next(); 

} catch (err) { 
  return res.status(401).json({ status: false, message: 
    'Invalid or expired token' }); 
  } 
}; 

export const authenticateToken = (req: Request, res: 
  Response, next: NextFunction) => { 
    const authHeader = req.headers['authorization']; 
    const token = authHeader && authHeader.split(' ')[1]; 
    if (!token) return res.status(401).json({ status: false, 
      message: 'No token provided' }); 
      
jwt.verify(token, JWT_SECRET, (err, decoded) => { 
  if (err) return res.status(403).json({ status: false, message: 
    'Invalid token' }); 
    (req as any).user = decoded; 
    next(); 
  }); 
};


/**
 * Middleware สำหรับตรวจสอบว่าผู้ใช้ที่ล็อกอินมี role เป็น 'admin' หรือไม่
 */
export const isAdmin = (req: Request, res: Response, next: NextFunction) => {
  // req.user จะถูกสร้างโดย authenticateToken middleware
  const user = (req as any).user;

  if (user && user.role === 'admin') {
    next(); // ถ้าเป็น admin ให้ผ่านไปทำงานต่อ
  } else {
    res.status(403).json({ status: false, message: 'Forbidden: Admins only' });
  }
};