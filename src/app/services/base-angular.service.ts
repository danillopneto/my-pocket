import { AngularFirestore, QueryFn, AngularFirestoreCollection, DocumentChangeAction } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { BaseResourceModel } from '../models/base-resource.model';

export abstract class BaseAngularService<T extends BaseResourceModel>{
    constructor(protected firestore: AngularFirestore) {
    }

    abstract getCollectionReference(queryFn?: QueryFn): AngularFirestoreCollection<T>

    get(id: string): Observable<T | undefined> {
        return this.getCollectionReference().doc<T>(id).valueChanges();
    }

    getAll(orderBy?: string): Observable<T[]> {
        if (orderBy != null
            && orderBy != '') {
            return this.getCollectionReference(ref => ref.orderBy(orderBy)).valueChanges();
        }

        return this.getCollectionReference().valueChanges();
    }

    getAllWithQuery(queryFn?: QueryFn): Observable<T[]> {
        if (queryFn != null) {
            return this.getCollectionReference(queryFn).valueChanges();
        }

        return this.getCollectionReference().valueChanges();
    }

    remove(id: string): Promise<void> {
        return this.getCollectionReference().doc(id).delete();
    }

    save(model: T): Promise<void> {
      if (model.id == null || model.id == '') {
        const uuidv1 = require('uuid/v1');
        model.id = uuidv1();
      }
  
      return this.getCollectionReference().doc(model.id).set({... model});
    }
}