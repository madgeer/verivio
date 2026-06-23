import { Router } from "express";
import { verifyAnswer } from "../controllers/verificationController";

const router = Router();

router.post('/verify', verifyAnswer);

export default router;