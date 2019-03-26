import { BaseResourceModel } from './base-resource.model';

export class Category extends BaseResourceModel {
    constructor(
        public id?: string,
        public color?: string,
        public description?: string) {
        super();
    }
}