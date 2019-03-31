import { Category } from './category.model';
import { PaymentMethod } from './payment-method.model';

export class Expense {
    category: Category;
    paymentMethod: PaymentMethod;
    
    constructor(
        public id: string = '',
        public day: string = null,
        public month: string = null,
        public year: string = null,
        public idCategory: string = null,
        public description: string = '',
        public value: number = null,
        public idPaymentMethod: string = null) {
    }
}