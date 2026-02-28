'use client';
import { motion } from 'framer-motion';

interface KineticTextProps {
  text: string;
  className?: string;
  as?: 'h1' | 'h2' | 'h3' | 'p' | 'span';
  delay?: number;
}

export const KineticText: React.FC<KineticTextProps> = ({
  text,
  className = '',
  as: Component = 'span',
  delay = 0
}) => {
  return (
    <Component className={`inline-block ${className}`}>
      {text.split('').map((char, i) => (
        <motion.span
          key={i}
          initial={{ opacity: 0, filter: 'blur(10px)', y: 20 }}
          animate={{ opacity: 1, filter: 'blur(0px)', y: 0 }}
          transition={{
            duration: 0.8,
            ease: [0.19, 1, 0.22, 1],
            delay: delay + i * 0.015
          }}
          style={{
            display: char === ' ' ? 'inline' : 'inline-block',
            marginRight: char === ' ' ? '0.25em' : '-0.08em'
          }}
        >
          {char}
        </motion.span>
      ))}
    </Component>
  );
};
