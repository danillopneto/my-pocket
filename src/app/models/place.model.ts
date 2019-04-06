import { BaseResourceModel } from './base-resource.model';

export class Place extends BaseResourceModel {
    constructor(
        public id?: string,
        public description?: string) {
        super();
    }
}