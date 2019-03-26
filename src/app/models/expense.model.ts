import { PaymentMethod } from '../enumerators/enum.payment.method';

export class Expense {
    constructor(
        public id: string = '',
        public day: string = null,
        public month: string = null,
        public year: string = null,
        public idCategory: string = null,
        public description: string = '',
        public value: number = null,
        public paymentMethod: PaymentMethod = null) {
    }
}