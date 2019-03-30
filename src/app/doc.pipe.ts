import { Pipe, PipeTransform } from '@angular/core';
import { AngularFirestore, AngularFirestoreDocument } from '@angular/fire/firestore';
import { Observable } from 'rxjs';

@Pipe({
  name: 'doc'
})
export class DocPipe implements PipeTransform {

  constructor(private afs: AngularFirestore) { }

  transform(value: firebase.firestore.DocumentReference): Observable<any> {
    return this.afs.doc(value.path).valueChanges();
  }

}