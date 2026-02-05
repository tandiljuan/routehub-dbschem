-- Add value to enum type: "delivery_lot_state"
ALTER TYPE "public"."delivery_lot_state" ADD VALUE 'OPTIMIZING' AFTER 'PROCESSING';
