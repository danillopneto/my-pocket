export class Expense {
    category: firebase.firestore.DocumentReference;
    paymentMethod: firebase.firestore.DocumentReference;
    
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