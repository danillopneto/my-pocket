import { BaseResourceModel } from './base-resource.model';

export class PaymentMethod extends BaseResourceModel {
    constructor(
        public id?: string,
        public description?: string) {
        super();
    }
}