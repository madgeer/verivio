import { Router } from "express";
import { verifyAnswer, chatAI } from "../controllers/verificationController";

const router = Router();

router.post('/verify', verifyAnswer);
router.post('/chat', chatAI);

export default router;