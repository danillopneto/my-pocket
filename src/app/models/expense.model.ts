import { Category } from './category.model';
import { PaymentMethod } from './payment-method.model';

export class Expense {
    category: Category;
    paymentMethod: PaymentMethod;
    
    constructor(
        public id: string = '',
        public date: number = null,
        public day: number = null,
        public month: number = null,
        public year: number = null,
        public idCategory: string = null,
        public description: string = '',
        public value: number = null,
        public idPaymentMethod: string = null,
        public place: string = null) {
    }
}